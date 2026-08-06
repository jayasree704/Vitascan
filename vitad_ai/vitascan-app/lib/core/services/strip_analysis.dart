import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Vitamin D lateral-flow test strip analyser — pure code, no AI service.
///
/// Mirrors `vitadwebsite/src/lib/stripAnalysis.js` so the app and the website
/// return the same reading for the same photo.
///
/// On a real cassette the membrane sits in a recessed window and is barely
/// darker than the white plastic around it, so brightness alone cannot find
/// the lines. What *does* separate a developed line from everything else is
/// colour: the C and T lines are the only pink/red features on an otherwise
/// neutral cassette. The pipeline is therefore:
///
///   1. Score every pixel by colourfulness (max-min of RGB).
///   2. Group coloured pixels into connected components.
///   3. Keep components shaped like a test line — thin, elongated, and with
///      pale neutral membrane on both flanks. This rejects printed text, the
///      yellow result label and ordinary photos.
///   4. Measure each band's chroma above its own local membrane baseline.
///   5. Convert the T/C ratio into ng/mL through a Hill calibration curve.
///
/// When the picture is not a readable strip the analyser reports
/// [StripAnalysis.invalid] rather than inventing a number.

/* ─── Calibration ──────────────────────────────────────────── */

/// level(R) = maxLevel * R^hill / (R^hill + c50^hill), R = T/C chroma ratio.
///
/// This kit reads DIRECTLY, not competitively: a stronger test line means more
/// 25-OH-D. The reference photo supplied with the kit shows a control line
/// only, labelled "DEFICIENCY (Low Vitamin D)", so R = 0 must read as
/// deficient. Constants are fitted so the curve crosses the clinical
/// boundaries exactly: R=0.30 → 20 ng/mL and R=0.50 → 30 ng/mL.
class Calibration {
  static const double c50 = 0.78;
  static const double hill = 1.15;
  static const double minLevel = 5.0;
  static const double maxLevel = 80.0;
}

/* ─── Tunables ─────────────────────────────────────────────── */

const int _workMaxDim = 640; // analysis resolution (px, long edge)

// Pixel-level band candidates
const double _minColourfulness = 14; // 0-255, max-min of RGB
const double _minBandValue = 55; // below this it is printed text, not a line
const double _maxBandValue = 250;

// Band shape
const double _maxBandThicknessFraction = 0.06; // vs. the frame's long edge
const int _minBandLength = 12; // px at working resolution
const double _minBandElongation = 1.6;
const double _minBandFill = 0.35; // component area vs. its bounding box

// Flanks: the membrane either side of a genuine line
const double _minFlankValue = 90; // membrane is pale
const double _maxFlankColour = 16; // and close to neutral

// A developed line is a pale pink stripe, only slightly darker than the
// membrane it sits on (measured ~0.96 on the reference cassette). Printed
// text and the shadow along a cassette edge are far darker (~0.57), so this
// single ratio separates genuine lines from the things that look like them.
const double _minBandVsFlankValue = 0.70;

// Reading quality
const double _minControlChroma = 5.0; // chroma above the membrane baseline
const double _maxFlankImbalance = 0.35; // lighting difference between bands

/* ─── Result types ─────────────────────────────────────────── */

enum StripRejection {
  unreadable,
  tooSmall,
  noStrip,
  noControlLine,
  unevenLighting,
}

const Map<StripRejection, String> _rejectionText = {
  StripRejection.unreadable: 'The file could not be read as an image.',
  StripRejection.tooSmall:
      'The image resolution is too low to measure the test lines.',
  StripRejection.noStrip:
      'No Vitamin D test strip was found in this picture.',
  StripRejection.noControlLine:
      'No control (C) line was detected, so the strip cannot be read.',
  StripRejection.unevenLighting:
      'A shadow or glare falls across the strip, so the lines cannot be measured.',
};

class StripAnalysis {
  final bool isValid;
  final StripRejection? rejection;
  final String message;
  final double level;
  final String status;
  final double confidence;
  final Map<String, dynamic> measurements;

  const StripAnalysis._({
    required this.isValid,
    this.rejection,
    this.message = '',
    this.level = 0,
    this.status = '',
    this.confidence = 0,
    this.measurements = const {},
  });

  factory StripAnalysis.invalid(StripRejection reason,
          [Map<String, dynamic> details = const {}]) =>
      StripAnalysis._(
        isValid: false,
        rejection: reason,
        message:
            _rejectionText[reason] ?? _rejectionText[StripRejection.noStrip]!,
        measurements: details,
      );

  factory StripAnalysis.reading({
    required double level,
    required String status,
    required double confidence,
    required Map<String, dynamic> measurements,
  }) =>
      StripAnalysis._(
        isValid: true,
        level: level,
        status: status,
        confidence: confidence,
        measurements: measurements,
      );

  /// Human-readable summary stored alongside the scan for traceability.
  String get summary {
    if (!isValid) return 'Rejected: $message';
    return 'Colorimetric densitometry — '
        'C=${measurements['controlIntensity']}, '
        'T=${measurements['testIntensity']}, '
        'T/C=${measurements['ratio']}, '
        'bands=${measurements['bandCount']}, '
        'test line ${measurements['shadeName']} '
        '→ ${level.toStringAsFixed(1)} ng/mL ($status)';
  }
}

/* ─── Helpers ──────────────────────────────────────────────── */

double _clamp(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);

String statusForLevel(double level) {
  if (level < 20) return 'Deficient';
  if (level < 30) return 'Insufficient';
  return 'Sufficient';
}

/// How the test line reads by eye. The kit is graded by how deeply the T line
/// develops: pale pink means deficient, light pink insufficient, dark pink
/// sufficient. Both the shade and the status come from the same measured
/// level, so they can never disagree.
class LineShade {
  /// What the T line looks like, e.g. "Dark pink".
  final String name;

  /// Swatch approximating that shade, for the UI.
  final String hex;

  /// Clinical category the shade corresponds to.
  final String status;

  const LineShade(this.name, this.hex, this.status);

  Map<String, dynamic> toJson() => {'name': name, 'hex': hex, 'status': status};
}

const LineShade palePink = LineShade('Pale pink', '#F5C6D6', 'Deficient');
const LineShade lightPink = LineShade('Light pink', '#E87BA6', 'Insufficient');
const LineShade darkPink = LineShade('Dark pink', '#AD1457', 'Sufficient');

/// Ordered faintest → deepest, for reference guides.
const List<LineShade> lineShades = [palePink, lightPink, darkPink];

LineShade shadeForStatus(String status) {
  switch (status) {
    case 'Deficient':
      return palePink;
    case 'Sufficient':
      return darkPink;
    default:
      return lightPink;
  }
}

LineShade shadeForLevel(double level) => shadeForStatus(statusForLevel(level));

double _round(double v, int places) {
  final f = math.pow(10, places);
  return (v * f).round() / f;
}

/// Turn a T/C chroma ratio into a 25-OH-D concentration in ng/mL.
double ratioToLevel(double ratio) {
  if (ratio <= 0) return Calibration.minLevel;
  final r = math.pow(ratio, Calibration.hill);
  final c = math.pow(Calibration.c50, Calibration.hill);
  final level = Calibration.maxLevel * r / (r + c);
  return _clamp(_round(level.toDouble(), 1), Calibration.minLevel,
      Calibration.maxLevel);
}

/* ─── Band detection ───────────────────────────────────────── */

class _Band {
  final int minX, maxX, minY, maxY, area;
  double chroma = 0; // above the local membrane baseline
  double flankValue = 0; // membrane brightness beside the band
  double flankColour = 0;
  double bandValue = 0;

  _Band(this.minX, this.maxX, this.minY, this.maxY, this.area);

  int get width => maxX - minX + 1;
  int get height => maxY - minY + 1;
  bool get isVertical => height >= width;
  int get thickness => math.min(width, height);
  int get length => math.max(width, height);

  /// Position along the strip axis (perpendicular to the band).
  double get axisPosition => isVertical ? (minX + maxX) / 2 : (minY + maxY) / 2;

  /// Integrated signal, the quantity a strip reader actually compares.
  double get signal => chroma * length;
}

List<_Band> _findComponents(
    Uint8List mask, int width, int height, int minArea) {
  final n = width * height;
  final seen = Uint8List(n);
  final stack = Int32List(n);
  final bands = <_Band>[];

  for (var start = 0; start < n; start++) {
    if (mask[start] == 0 || seen[start] == 1) continue;

    var top = 0;
    stack[top++] = start;
    seen[start] = 1;

    var area = 0;
    var minX = width, maxX = -1, minY = height, maxY = -1;

    while (top > 0) {
      final idx = stack[--top];
      final x = idx % width;
      final y = idx ~/ width;

      area++;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;

      if (x > 0 && mask[idx - 1] == 1 && seen[idx - 1] == 0) {
        seen[idx - 1] = 1;
        stack[top++] = idx - 1;
      }
      if (x < width - 1 && mask[idx + 1] == 1 && seen[idx + 1] == 0) {
        seen[idx + 1] = 1;
        stack[top++] = idx + 1;
      }
      if (y > 0 && mask[idx - width] == 1 && seen[idx - width] == 0) {
        seen[idx - width] = 1;
        stack[top++] = idx - width;
      }
      if (y < height - 1 && mask[idx + width] == 1 && seen[idx + width] == 0) {
        seen[idx + width] = 1;
        stack[top++] = idx + width;
      }
    }

    if (area >= minArea) bands.add(_Band(minX, maxX, minY, maxY, area));
  }

  return bands;
}

/// Mean brightness and colourfulness over a rectangle, clipped to the frame.
({double value, double colour, int count}) _regionStats(Float32List value,
    Float32List colour, int width, int height, int x0, int x1, int y0, int y1) {
  var v = 0.0, c = 0.0;
  var count = 0;
  for (var y = math.max(0, y0); y <= math.min(height - 1, y1); y++) {
    for (var x = math.max(0, x0); x <= math.min(width - 1, x1); x++) {
      final i = y * width + x;
      v += value[i];
      c += colour[i];
      count++;
    }
  }
  if (count == 0) return (value: 0, colour: 0, count: 0);
  return (value: v / count, colour: c / count, count: count);
}

/// Keeps only components shaped and situated like a developed test line.
List<_Band> _keepLineShapedBands(List<_Band> candidates, Float32List value,
    Float32List colour, int width, int height) {
  final maxThickness = math.max(width, height) * _maxBandThicknessFraction;
  final kept = <_Band>[];

  for (final b in candidates) {
    if (b.length < _minBandLength) continue;
    if (b.thickness > maxThickness) continue; // the yellow label, a big blob
    if (b.length / b.thickness < _minBandElongation) continue; // printed C/T/S
    if (b.area / (b.width * b.height) < _minBandFill) continue;

    // The membrane on either side of the line, one band-thickness away.
    final offset = math.max(3, b.thickness);
    final span = math.max(3, b.thickness);

    final ({double value, double colour, int count}) near, far;
    if (b.isVertical) {
      near = _regionStats(value, colour, width, height, b.minX - offset - span,
          b.minX - offset, b.minY, b.maxY);
      far = _regionStats(value, colour, width, height, b.maxX + offset,
          b.maxX + offset + span, b.minY, b.maxY);
    } else {
      near = _regionStats(value, colour, width, height, b.minX, b.maxX,
          b.minY - offset - span, b.minY - offset);
      far = _regionStats(value, colour, width, height, b.minX, b.maxX,
          b.maxY + offset, b.maxY + offset + span);
    }
    if (near.count == 0 || far.count == 0) continue; // line runs off-frame

    // Both flanks must look like bare membrane: pale and close to neutral.
    final flankValue = (near.value + far.value) / 2;
    final flankColour = (near.colour + far.colour) / 2;
    if (near.value < _minFlankValue || far.value < _minFlankValue) continue;
    if (near.colour > _maxFlankColour || far.colour > _maxFlankColour) continue;

    final band =
        _regionStats(value, colour, width, height, b.minX, b.maxX, b.minY, b.maxY);

    // A test line is a pale pink stripe, not dark printed text.
    if (band.value < _minBandVsFlankValue * flankValue) continue;

    b.chroma = math.max(0, band.colour - flankColour);
    b.flankValue = flankValue;
    b.flankColour = flankColour;
    b.bandValue = band.value;
    kept.add(b);
  }

  return kept;
}

/// Bands belong to the same strip when they share an orientation and overlap
/// along their length — the C and T lines are parallel and side by side.
List<_Band> _largestParallelGroup(List<_Band> bands) {
  if (bands.length <= 1) return bands;

  List<_Band> best = [];
  for (final seed in bands) {
    final group = <_Band>[];
    for (final b in bands) {
      if (b.isVertical != seed.isVertical) continue;

      // Overlap measured along the bands' shared long axis.
      final aLo = seed.isVertical ? seed.minY : seed.minX;
      final aHi = seed.isVertical ? seed.maxY : seed.maxX;
      final bLo = b.isVertical ? b.minY : b.minX;
      final bHi = b.isVertical ? b.maxY : b.maxX;
      final overlap = math.min(aHi, bHi) - math.max(aLo, bLo);
      if (overlap < 0.5 * math.min(seed.length, b.length)) continue;

      group.add(b);
    }
    if (group.length > best.length ||
        (group.length == best.length &&
            group.fold<double>(0, (s, x) => s + x.signal) >
                best.fold<double>(0, (s, x) => s + x.signal))) {
      best = group;
    }
  }
  return best;
}

/* ─── Main entry points ────────────────────────────────────── */

/// Decode, downscale and analyse encoded image bytes.
/// Safe to run inside an isolate (`compute`).
StripAnalysis analyzeStripBytes(Uint8List bytes) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    return StripAnalysis.invalid(StripRejection.unreadable);
  }
  if (decoded == null) return StripAnalysis.invalid(StripRejection.unreadable);

  final longest = math.max(decoded.width, decoded.height);
  if (longest > _workMaxDim) {
    decoded = decoded.width >= decoded.height
        ? img.copyResize(decoded, width: _workMaxDim)
        : img.copyResize(decoded, height: _workMaxDim);
  }

  final width = decoded.width;
  final height = decoded.height;
  if (width < 80 || height < 80) {
    return StripAnalysis.invalid(StripRejection.tooSmall);
  }

  final n = width * height;
  final value = Float32List(n);
  final colour = Float32List(n);

  var i = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final p = decoded.getPixel(x, y);
      final r = p.r.toDouble(), g = p.g.toDouble(), b = p.b.toDouble();
      final mx = math.max(r, math.max(g, b));
      final mn = math.min(r, math.min(g, b));
      value[i] = mx;
      colour[i] = mx - mn;
      i++;
    }
  }

  return analyzePixels(value, colour, width, height);
}

StripAnalysis analyzePixels(
    Float32List value, Float32List colour, int width, int height) {
  final n = width * height;

  final mask = Uint8List(n);
  for (var i = 0; i < n; i++) {
    mask[i] = (colour[i] >= _minColourfulness &&
            value[i] >= _minBandValue &&
            value[i] <= _maxBandValue)
        ? 1
        : 0;
  }

  final minArea = math.max(12, (_minBandLength * 1.5).round());
  final candidates = _findComponents(mask, width, height, minArea);
  if (candidates.isEmpty) return StripAnalysis.invalid(StripRejection.noStrip);

  final lineShaped = _keepLineShapedBands(candidates, value, colour, width, height);
  if (lineShaped.isEmpty) {
    return StripAnalysis.invalid(
        StripRejection.noStrip, {'candidateCount': candidates.length});
  }

  // Rank by chroma, not integrated signal: a long faint artefact must never
  // outrank a genuine line just because it is longer.
  final group = _largestParallelGroup(lineShaped)
    ..sort((a, b) => b.chroma.compareTo(a.chroma));
  if (group.isEmpty) return StripAnalysis.invalid(StripRejection.noStrip);

  // Keep the two strongest bands: a cassette shows at most C and T.
  final bands = group.take(2).toList();

  if (bands.first.chroma < _minControlChroma) {
    return StripAnalysis.invalid(StripRejection.noControlLine,
        {'controlChroma': _round(bands.first.chroma, 2)});
  }

  _Band control;
  _Band? test;
  if (bands.length == 1) {
    // A valid strip always develops its control line, so a lone band is C and
    // the test line is absent.
    control = bands[0];
  } else {
    final a = bands[0], b = bands[1];

    // Both lines must sit under comparable lighting for the ratio to mean
    // anything.
    final hi = math.max(a.flankValue, b.flankValue);
    final lo = math.min(a.flankValue, b.flankValue);
    if (hi > 0 && (hi - lo) / hi > _maxFlankImbalance) {
      return StripAnalysis.invalid(StripRejection.unevenLighting,
          {'flankImbalance': _round((hi - lo) / hi, 3)});
    }

    // The control line sits downstream of the test line, i.e. nearer the far
    // end of the result window, so it is the outer of the two.
    final axisLength = (a.isVertical ? width : height).toDouble();
    double distanceToEnd(_Band x) =>
        math.min(x.axisPosition, axisLength - x.axisPosition);
    if (distanceToEnd(a) <= distanceToEnd(b)) {
      control = a;
      test = b;
    } else {
      control = b;
      test = a;
    }
  }

  final ratio = control.signal > 0
      ? _clamp((test?.signal ?? 0) / control.signal, 0, 3)
      : 0.0;
  final level = ratioToLevel(ratio);
  final status = statusForLevel(level);
  final shade = shadeForStatus(status);

  final controlQuality = _clamp(control.chroma / 25, 0, 1);
  final geometryQuality = _clamp(control.length / 40, 0, 1);
  final exposureQuality =
      1 - _clamp((control.flankValue - 180).abs() / 120, 0, 1);
  final confidence = _round(
    _clamp(
      0.70 +
          0.29 *
              (0.45 * controlQuality +
                  0.30 * geometryQuality +
                  0.25 * exposureQuality),
      0.70,
      0.99,
    ),
    2,
  );

  return StripAnalysis.reading(
    level: level,
    status: status,
    confidence: confidence,
    measurements: {
      'shadeName': shade.name,
      'shadeHex': shade.hex,
      'controlIntensity': _round(control.chroma, 2),
      'testIntensity': _round(test?.chroma ?? 0, 2),
      'controlSignal': _round(control.signal, 1),
      'testSignal': _round(test?.signal ?? 0, 1),
      'ratio': _round(ratio, 4),
      'bandCount': bands.length,
      'testLineVisible': test != null,
      'stripOrientation': control.isVertical ? 'horizontal' : 'vertical',
      'membraneBrightness': _round(control.flankValue, 1),
      'controlLength': control.length,
      'controlThickness': control.thickness,
    },
  );
}
