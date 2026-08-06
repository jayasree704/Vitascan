import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:vitad_ai/core/services/strip_analysis.dart';

/// Synthetic fixtures mirror the JS ones in
/// `vitadwebsite/src/lib/stripAnalysis.js`, so both platforms are checked
/// against the same inputs. Line colours follow the real reference cassette:
/// a developed line is a pale pink stripe only slightly darker than the
/// membrane, not a dark bar.

img.Image _canvas(int w, int h, List<int> fill) {
  final image = img.Image(width: w, height: h);
  img.fill(image, color: img.ColorRgb8(fill[0], fill[1], fill[2]));
  return image;
}

void _fillRect(img.Image im, int x0, int y0, int x1, int y1, List<int> c) {
  for (var y = y0; y <= y1; y++) {
    for (var x = x0; x <= x1; x++) {
      if (x < 0 || y < 0 || x >= im.width || y >= im.height) continue;
      im.setPixelRgb(x, y, c[0], c[1], c[2]);
    }
  }
}

/// A colloidal-gold line: red channel stays near the membrane, green drops
/// most, blue drops somewhat. [strength] 0-100 sets how developed it is.
List<int> _lineColour(double strength) => [
      (238 - strength * 0.10).round(),
      (238 - strength).round(),
      (238 - strength * 0.60).round(),
    ];

/// `axis == 'h'` draws a vertical line at column [pos] spanning rows a0..a1.
void _band(img.Image im, String axis, int pos, double strength, int halfW,
    int a0, int a1) {
  final c = _lineColour(strength);
  for (var d = -halfW; d <= halfW; d++) {
    if (axis == 'v') {
      _fillRect(im, a0, pos + d, a1, pos + d, c);
    } else {
      _fillRect(im, pos + d, a0, pos + d, a1, c);
    }
  }
}

img.Image _syntheticStrip({
  required double controlStrength,
  required double testStrength,
}) {
  final im = _canvas(512, 256, [120, 120, 125]);
  _fillRect(im, 60, 90, 440, 170, [238, 238, 236]); // membrane
  if (testStrength > 0) _band(im, 'h', 200, testStrength, 5, 95, 165);
  _band(im, 'h', 320, controlStrength, 5, 95, 165);
  return im;
}

Uint8List _png(img.Image im) => Uint8List.fromList(img.encodePng(im));

/// The photo supplied with the kit, labelled "DEFICIENCY (Low Vitamin D)".
const _referenceSample = 'test/fixtures/reference_deficiency.jpeg';

void main() {
  group('calibration curve', () {
    test('reads directly: a stronger test line means more Vitamin D', () {
      final ratios = [0.0, 0.2, 0.3, 0.5, 0.8, 1.0, 1.5];
      final levels = ratios.map(ratioToLevel).toList();
      for (var i = 1; i < levels.length; i++) {
        expect(levels[i], greaterThanOrEqualTo(levels[i - 1]),
            reason: 'ratio ${ratios[i]} must not read lower than ${ratios[i - 1]}');
      }
    });

    test('crosses the clinical boundaries at the fitted ratios', () {
      expect(ratioToLevel(0.0), Calibration.minLevel); // no test line
      expect(ratioToLevel(0.30), closeTo(20.0, 0.3)); // Deficient/Insufficient
      expect(ratioToLevel(0.50), closeTo(30.0, 0.3)); // Insufficient/Sufficient
    });

    test('status thresholds follow the clinical ranges', () {
      expect(statusForLevel(12.0), 'Deficient');
      expect(statusForLevel(19.9), 'Deficient');
      expect(statusForLevel(20.0), 'Insufficient');
      expect(statusForLevel(29.9), 'Insufficient');
      expect(statusForLevel(30.0), 'Sufficient');
    });
  });

  group('test line shade', () {
    test('maps pale/light/dark pink to the clinical categories', () {
      expect(shadeForLevel(8.0).name, 'Pale pink');
      expect(shadeForLevel(19.9).name, 'Pale pink');
      expect(shadeForLevel(20.0).name, 'Light pink');
      expect(shadeForLevel(29.9).name, 'Light pink');
      expect(shadeForLevel(30.0).name, 'Dark pink');
      expect(shadeForLevel(65.0).name, 'Dark pink');
    });

    test('shade and status can never disagree', () {
      for (var level = 5.0; level <= 80.0; level += 0.5) {
        expect(shadeForLevel(level).status, statusForLevel(level),
            reason: 'at $level ng/mL');
      }
    });

    test('shades are ordered faintest to deepest', () {
      expect(lineShades.map((s) => s.name).toList(),
          ['Pale pink', 'Light pink', 'Dark pink']);
      expect(lineShades.map((s) => s.status).toList(),
          ['Deficient', 'Insufficient', 'Sufficient']);
    });

    test('a reading carries the shade that matches its status', () {
      final absent = analyzeStripBytes(
          _png(_syntheticStrip(controlStrength: 90, testStrength: 0)));
      expect(absent.measurements['shadeName'], 'Pale pink');
      expect(absent.status, 'Deficient');

      final strong = analyzeStripBytes(
          _png(_syntheticStrip(controlStrength: 90, testStrength: 95)));
      expect(strong.measurements['shadeName'], 'Dark pink');
      expect(strong.status, 'Sufficient');
    });
  });

  group('reference cassette photo', () {
    final file = File(_referenceSample);

    test('the kit reference photo is accepted and reads Deficient', () {
      expect(file.existsSync(), isTrue,
          reason: 'missing fixture $_referenceSample');
      final r = analyzeStripBytes(Uint8List.fromList(file.readAsBytesSync()));

      expect(r.isValid, isTrue, reason: r.message);
      // The kit labels this photo "DEFICIENCY (Low Vitamin D)": control line
      // only, no test line.
      expect(r.status, 'Deficient');
      expect(r.measurements['testLineVisible'], isFalse);
      expect(r.measurements['bandCount'], 1);

      // It must lock onto the real C line, not the shadow along the cassette
      // edge, which is longer but far darker than its surroundings.
      expect(r.measurements['controlLength'], lessThan(45));
      expect(r.measurements['membraneBrightness'], greaterThan(120));
    });
  });

  group('valid strips', () {
    test('a stronger test line reads as a higher Vitamin D level', () {
      final absent = analyzeStripBytes(
          _png(_syntheticStrip(controlStrength: 90, testStrength: 0)));
      final faint = analyzeStripBytes(
          _png(_syntheticStrip(controlStrength: 90, testStrength: 25)));
      final medium = analyzeStripBytes(
          _png(_syntheticStrip(controlStrength: 90, testStrength: 55)));
      final strong = analyzeStripBytes(
          _png(_syntheticStrip(controlStrength: 90, testStrength: 95)));

      for (final r in [absent, faint, medium, strong]) {
        expect(r.isValid, isTrue, reason: r.message);
      }

      expect(absent.level, lessThan(faint.level));
      expect(faint.level, lessThan(medium.level));
      expect(medium.level, lessThan(strong.level));

      expect(absent.status, 'Deficient');
      expect(strong.status, 'Sufficient');
    });

    test('identifies both lines when the test line is present', () {
      final r = analyzeStripBytes(
          _png(_syntheticStrip(controlStrength: 90, testStrength: 55)));
      expect(r.measurements['bandCount'], 2);
      expect(r.measurements['testLineVisible'], isTrue);
      expect(r.confidence, inInclusiveRange(0.70, 0.99));
    });

    test('reads a vertically oriented strip', () {
      final im = _canvas(300, 512, [60, 62, 70]);
      _fillRect(im, 105, 50, 195, 460, [236, 236, 233]);
      _band(im, 'v', 210, 45, 5, 115, 185); // T
      _band(im, 'v', 330, 90, 5, 115, 185); // C

      final r = analyzeStripBytes(_png(im));
      expect(r.isValid, isTrue, reason: r.message);
      expect(r.measurements['bandCount'], 2);
      expect(r.measurements['testLineVisible'], isTrue);
    });
  });

  group('rejects images that are not a Vitamin D test strip', () {
    test('a blank membrane with no lines', () {
      final im = _canvas(512, 256, [120, 120, 125]);
      _fillRect(im, 60, 90, 440, 170, [238, 238, 236]);
      final r = analyzeStripBytes(_png(im));
      expect(r.isValid, isFalse);
      expect(r.rejection, StripRejection.noStrip);
    });

    test('a colourful everyday photo', () {
      final im = img.Image(width: 512, height: 384);
      for (var y = 0; y < 384; y++) {
        for (var x = 0; x < 512; x++) {
          im.setPixelRgb(
            x,
            y,
            (math.sin(x / 9) * 90 + 120).toInt(),
            (math.cos(y / 7) * 70 + 90).toInt(),
            (x * y) % 160,
          );
        }
      }
      final r = analyzeStripBytes(_png(im));
      expect(r.isValid, isFalse);
    });

    test('a skin-tone portrait', () {
      final im = _canvas(512, 384, [196, 148, 118]);
      _fillRect(im, 150, 90, 360, 320, [212, 166, 134]);
      final r = analyzeStripBytes(_png(im));
      expect(r.isValid, isFalse);
    });

    test('a plain white card', () {
      final im = _canvas(512, 384, [120, 120, 125]);
      _fillRect(im, 150, 100, 360, 300, [238, 238, 236]);
      final r = analyzeStripBytes(_png(im));
      expect(r.isValid, isFalse);
    });

    test('a page of printed text', () {
      final im = _canvas(420, 560, [245, 245, 243]);
      for (var row = 0; row < 14; row++) {
        _fillRect(im, 40, 60 + row * 35, 380, 60 + row * 35 + 9, [40, 40, 45]);
      }
      final r = analyzeStripBytes(_png(im));
      expect(r.isValid, isFalse);
    });

    test('a dark edge shadow is not mistaken for a line', () {
      // Same geometry as a test line but far darker than its surroundings —
      // this is what the cassette's moulded edge looks like.
      final im = _canvas(512, 256, [120, 120, 125]);
      _fillRect(im, 60, 90, 440, 170, [238, 238, 236]);
      _fillRect(im, 315, 95, 325, 165, [96, 88, 84]);
      final r = analyzeStripBytes(_png(im));
      expect(r.isValid, isFalse);
    });

    test('an image too small to measure', () {
      final r = analyzeStripBytes(_png(_canvas(50, 40, [120, 120, 125])));
      expect(r.isValid, isFalse);
      expect(r.rejection, StripRejection.tooSmall);
    });

    test('bytes that are not an image at all', () {
      final r = analyzeStripBytes(Uint8List.fromList([1, 2, 3, 4, 5]));
      expect(r.isValid, isFalse);
      expect(r.rejection, StripRejection.unreadable);
    });
  });
}
