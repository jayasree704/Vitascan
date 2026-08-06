/**
 * Vitamin D lateral-flow test strip analyser — pure code, no AI service.
 *
 * Mirrors `vitad_ai/vitascan-app/lib/core/services/strip_analysis.dart` so the
 * website and the app return the same reading for the same photo.
 *
 * On a real cassette the membrane sits in a recessed window and is barely
 * darker than the white plastic around it, so brightness alone cannot find the
 * lines. What *does* separate a developed line from everything else is colour:
 * the C and T lines are the only pink/red features on an otherwise neutral
 * cassette. The pipeline is therefore:
 *
 *   1. Score every pixel by colourfulness (max-min of RGB).
 *   2. Group coloured pixels into connected components.
 *   3. Keep components shaped like a test line — thin, elongated, and with
 *      pale neutral membrane on both flanks. This rejects printed text, the
 *      yellow result label and ordinary photos.
 *   4. Measure each band's chroma above its own local membrane baseline.
 *   5. Convert the T/C ratio into ng/mL through a Hill calibration curve.
 *
 * If the picture does not contain a readable strip, the analyser returns
 * `{ valid: false, reason, message }` instead of inventing a number.
 */

/* ─── Calibration ──────────────────────────────────────────── */

/**
 * level(R) = maxLevel * R^hill / (R^hill + c50^hill), R = T/C chroma ratio.
 *
 * This kit reads DIRECTLY, not competitively: a stronger test line means more
 * 25-OH-D. The reference photo supplied with the kit shows a control line
 * only, labelled "DEFICIENCY (Low Vitamin D)", so R = 0 must read as
 * deficient. Constants are fitted so the curve crosses the clinical
 * boundaries exactly: R=0.30 → 20 ng/mL and R=0.50 → 30 ng/mL.
 */
export const CALIBRATION = {
  c50: 0.78,
  hill: 1.15,
  minLevel: 5.0,
  maxLevel: 80.0,
};

/* ─── Tunables ─────────────────────────────────────────────── */

const WORK_MAX_DIM = 640;      // analysis resolution (px, long edge)

// Pixel-level band candidates
const MIN_COLOURFULNESS = 14;  // 0-255, max-min of RGB
const MIN_BAND_VALUE = 55;     // below this it is printed text, not a line
const MAX_BAND_VALUE = 250;

// Band shape
const MAX_BAND_THICKNESS_FRACTION = 0.06; // vs. the frame's long edge
const MIN_BAND_LENGTH = 12;    // px at working resolution
const MIN_BAND_ELONGATION = 1.6;
const MIN_BAND_FILL = 0.35;    // component area vs. its bounding box

// Flanks: the membrane either side of a genuine line
const MIN_FLANK_VALUE = 90;    // membrane is pale
const MAX_FLANK_COLOUR = 16;   // and close to neutral

// A developed line is a pale pink stripe, only slightly darker than the
// membrane it sits on (measured ~0.96 on the reference cassette). Printed text
// and the shadow along a cassette edge are far darker (~0.57), so this single
// ratio separates genuine lines from the things that look like them.
const MIN_BAND_VS_FLANK_VALUE = 0.70;

// Reading quality
const MIN_CONTROL_CHROMA = 5.0;   // chroma above the membrane baseline
const MAX_FLANK_IMBALANCE = 0.35; // lighting difference between bands

export const REJECTION = {
  UNREADABLE: 'UNREADABLE',
  TOO_SMALL: 'TOO_SMALL',
  NO_STRIP: 'NO_STRIP',
  NO_CONTROL_LINE: 'NO_CONTROL_LINE',
  UNEVEN_LIGHTING: 'UNEVEN_LIGHTING',
};

const REJECTION_TEXT = {
  [REJECTION.UNREADABLE]: 'The file could not be read as an image.',
  [REJECTION.TOO_SMALL]: 'The image resolution is too low to measure the test lines.',
  [REJECTION.NO_STRIP]: 'No Vitamin D test strip was found in this picture.',
  [REJECTION.NO_CONTROL_LINE]: 'No control (C) line was detected, so the strip cannot be read.',
  [REJECTION.UNEVEN_LIGHTING]: 'A shadow or glare falls across the strip, so the lines cannot be measured.',
};

/* ─── Small helpers ────────────────────────────────────────── */

const clamp = (v, lo, hi) => (v < lo ? lo : v > hi ? hi : v);
const round = (v, places) => Number(v.toFixed(places));

export function statusForLevel(level) {
  if (level < 20) return 'Deficient';
  if (level < 30) return 'Insufficient';
  return 'Sufficient';
}

/**
 * How the test line reads by eye. The kit is graded by how deeply the T line
 * develops: pale pink means deficient, light pink insufficient, dark pink
 * sufficient. Both the shade and the status come from the same measured level,
 * so they can never disagree.
 *
 * Ordered faintest → deepest, for reference guides.
 */
export const LINE_SHADES = [
  { name: 'Pale pink', hex: '#F5C6D6', status: 'Deficient' },
  { name: 'Light pink', hex: '#E87BA6', status: 'Insufficient' },
  { name: 'Dark pink', hex: '#AD1457', status: 'Sufficient' },
];

export function shadeForStatus(status) {
  return LINE_SHADES.find((s) => s.status === status) || LINE_SHADES[1];
}

export function shadeForLevel(level) {
  return shadeForStatus(statusForLevel(level));
}

function reject(reason, extra = {}) {
  return {
    valid: false,
    reason,
    message: REJECTION_TEXT[reason] || REJECTION_TEXT[REJECTION.NO_STRIP],
    ...extra,
  };
}

/** Turn a T/C chroma ratio into a 25-OH-D concentration in ng/mL. */
export function ratioToLevel(ratio) {
  const { c50, hill, minLevel, maxLevel } = CALIBRATION;
  if (ratio <= 0) return minLevel;
  const r = Math.pow(ratio, hill);
  const c = Math.pow(c50, hill);
  return clamp(round((maxLevel * r) / (r + c), 1), minLevel, maxLevel);
}

/* ─── Image loading ────────────────────────────────────────── */

async function loadDrawable(source) {
  if (typeof source === 'string') {
    return await new Promise((resolve, onError) => {
      const img = new Image();
      img.onload = () => resolve(img);
      img.onerror = () => onError(new Error('unreadable'));
      img.src = source;
    });
  }
  if (typeof createImageBitmap === 'function') {
    return await createImageBitmap(source);
  }
  const url = URL.createObjectURL(source);
  try {
    return await new Promise((resolve, onError) => {
      const img = new Image();
      img.onload = () => resolve(img);
      img.onerror = () => onError(new Error('unreadable'));
      img.src = url;
    });
  } finally {
    URL.revokeObjectURL(url);
  }
}

function toImageData(drawable) {
  const srcW = drawable.width || drawable.naturalWidth;
  const srcH = drawable.height || drawable.naturalHeight;
  const scale = Math.min(1, WORK_MAX_DIM / Math.max(srcW, srcH));
  const w = Math.max(1, Math.round(srcW * scale));
  const h = Math.max(1, Math.round(srcH * scale));

  const canvas = document.createElement('canvas');
  canvas.width = w;
  canvas.height = h;
  const ctx = canvas.getContext('2d', { willReadFrequently: true });
  ctx.drawImage(drawable, 0, 0, w, h);
  return ctx.getImageData(0, 0, w, h);
}

/* ─── Band detection ───────────────────────────────────────── */

function makeBand(minX, maxX, minY, maxY, area) {
  const width = maxX - minX + 1;
  const height = maxY - minY + 1;
  const isVertical = height >= width;
  return {
    minX, maxX, minY, maxY, area, width, height, isVertical,
    thickness: Math.min(width, height),
    length: Math.max(width, height),
    // Position along the strip axis (perpendicular to the band).
    axisPosition: isVertical ? (minX + maxX) / 2 : (minY + maxY) / 2,
    chroma: 0,      // above the local membrane baseline
    flankValue: 0,  // membrane brightness beside the band
    flankColour: 0,
    bandValue: 0,
    get signal() { return this.chroma * this.length; },
  };
}

function findComponents(mask, width, height, minArea) {
  const n = width * height;
  const seen = new Uint8Array(n);
  const stack = new Int32Array(n);
  const bands = [];

  for (let start = 0; start < n; start++) {
    if (!mask[start] || seen[start]) continue;

    let top = 0;
    stack[top++] = start;
    seen[start] = 1;

    let area = 0;
    let minX = width, maxX = -1, minY = height, maxY = -1;

    while (top > 0) {
      const idx = stack[--top];
      const x = idx % width;
      const y = (idx - x) / width;

      area++;
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;

      if (x > 0 && mask[idx - 1] && !seen[idx - 1]) { seen[idx - 1] = 1; stack[top++] = idx - 1; }
      if (x < width - 1 && mask[idx + 1] && !seen[idx + 1]) { seen[idx + 1] = 1; stack[top++] = idx + 1; }
      if (y > 0 && mask[idx - width] && !seen[idx - width]) { seen[idx - width] = 1; stack[top++] = idx - width; }
      if (y < height - 1 && mask[idx + width] && !seen[idx + width]) { seen[idx + width] = 1; stack[top++] = idx + width; }
    }

    if (area >= minArea) bands.push(makeBand(minX, maxX, minY, maxY, area));
  }

  return bands;
}

/** Mean brightness and colourfulness over a rectangle, clipped to the frame. */
function regionStats(value, colour, width, height, x0, x1, y0, y1) {
  let v = 0;
  let c = 0;
  let count = 0;
  for (let y = Math.max(0, y0); y <= Math.min(height - 1, y1); y++) {
    for (let x = Math.max(0, x0); x <= Math.min(width - 1, x1); x++) {
      const i = y * width + x;
      v += value[i];
      c += colour[i];
      count++;
    }
  }
  if (count === 0) return { value: 0, colour: 0, count: 0 };
  return { value: v / count, colour: c / count, count };
}

/** Keeps only components shaped and situated like a developed test line. */
function keepLineShapedBands(candidates, value, colour, width, height) {
  const maxThickness = Math.max(width, height) * MAX_BAND_THICKNESS_FRACTION;
  const kept = [];

  for (const b of candidates) {
    if (b.length < MIN_BAND_LENGTH) continue;
    if (b.thickness > maxThickness) continue;                      // the yellow label
    if (b.length / b.thickness < MIN_BAND_ELONGATION) continue;    // printed C/T/S
    if (b.area / (b.width * b.height) < MIN_BAND_FILL) continue;

    // The membrane on either side of the line, one band-thickness away.
    const offset = Math.max(3, b.thickness);
    const span = Math.max(3, b.thickness);

    const near = b.isVertical
      ? regionStats(value, colour, width, height, b.minX - offset - span, b.minX - offset, b.minY, b.maxY)
      : regionStats(value, colour, width, height, b.minX, b.maxX, b.minY - offset - span, b.minY - offset);
    const far = b.isVertical
      ? regionStats(value, colour, width, height, b.maxX + offset, b.maxX + offset + span, b.minY, b.maxY)
      : regionStats(value, colour, width, height, b.minX, b.maxX, b.maxY + offset, b.maxY + offset + span);

    if (near.count === 0 || far.count === 0) continue; // line runs off-frame

    // Both flanks must look like bare membrane: pale and close to neutral.
    const flankValue = (near.value + far.value) / 2;
    const flankColour = (near.colour + far.colour) / 2;
    if (near.value < MIN_FLANK_VALUE || far.value < MIN_FLANK_VALUE) continue;
    if (near.colour > MAX_FLANK_COLOUR || far.colour > MAX_FLANK_COLOUR) continue;

    const band = regionStats(value, colour, width, height, b.minX, b.maxX, b.minY, b.maxY);

    // A test line is a pale pink stripe, not dark printed text.
    if (band.value < MIN_BAND_VS_FLANK_VALUE * flankValue) continue;

    b.chroma = Math.max(0, band.colour - flankColour);
    b.flankValue = flankValue;
    b.flankColour = flankColour;
    b.bandValue = band.value;
    kept.push(b);
  }

  return kept;
}

/**
 * Bands belong to the same strip when they share an orientation and overlap
 * along their length — the C and T lines are parallel and side by side.
 */
function largestParallelGroup(bands) {
  if (bands.length <= 1) return bands;

  const totalSignal = (list) => list.reduce((s, x) => s + x.signal, 0);
  let best = [];

  for (const seed of bands) {
    const group = [];
    for (const b of bands) {
      if (b.isVertical !== seed.isVertical) continue;

      // Overlap measured along the bands' shared long axis.
      const aLo = seed.isVertical ? seed.minY : seed.minX;
      const aHi = seed.isVertical ? seed.maxY : seed.maxX;
      const bLo = b.isVertical ? b.minY : b.minX;
      const bHi = b.isVertical ? b.maxY : b.maxX;
      const overlap = Math.min(aHi, bHi) - Math.max(aLo, bLo);
      if (overlap < 0.5 * Math.min(seed.length, b.length)) continue;

      group.push(b);
    }
    if (group.length > best.length ||
        (group.length === best.length && totalSignal(group) > totalSignal(best))) {
      best = group;
    }
  }
  return best;
}

/* ─── Main entry points ────────────────────────────────────── */

export function analyzeImageData(imageData) {
  const { data, width, height } = imageData;
  if (width < 80 || height < 80) return reject(REJECTION.TOO_SMALL);

  const n = width * height;
  const value = new Float32Array(n);
  const colour = new Float32Array(n);

  for (let i = 0; i < n; i++) {
    const o = i * 4;
    const r = data[o], g = data[o + 1], b = data[o + 2];
    const mx = r > g ? (r > b ? r : b) : (g > b ? g : b);
    const mn = r < g ? (r < b ? r : b) : (g < b ? g : b);
    value[i] = mx;
    colour[i] = mx - mn;
  }

  return analyzePixels(value, colour, width, height);
}

export function analyzePixels(value, colour, width, height) {
  const n = width * height;

  const mask = new Uint8Array(n);
  for (let i = 0; i < n; i++) {
    mask[i] = colour[i] >= MIN_COLOURFULNESS &&
      value[i] >= MIN_BAND_VALUE &&
      value[i] <= MAX_BAND_VALUE ? 1 : 0;
  }

  const minArea = Math.max(12, Math.round(MIN_BAND_LENGTH * 1.5));
  const candidates = findComponents(mask, width, height, minArea);
  if (candidates.length === 0) return reject(REJECTION.NO_STRIP);

  const lineShaped = keepLineShapedBands(candidates, value, colour, width, height);
  if (lineShaped.length === 0) {
    return reject(REJECTION.NO_STRIP, { candidateCount: candidates.length });
  }

  // Rank by chroma, not integrated signal: a long faint artefact must never
  // outrank a genuine line just because it is longer.
  const group = largestParallelGroup(lineShaped).sort((a, b) => b.chroma - a.chroma);
  if (group.length === 0) return reject(REJECTION.NO_STRIP);

  // Keep the two strongest bands: a cassette shows at most C and T.
  const bands = group.slice(0, 2);

  if (bands[0].chroma < MIN_CONTROL_CHROMA) {
    return reject(REJECTION.NO_CONTROL_LINE, { controlChroma: round(bands[0].chroma, 2) });
  }

  let control;
  let test = null;
  if (bands.length === 1) {
    // A valid strip always develops its control line, so a lone band is C and
    // the test line is absent.
    control = bands[0];
  } else {
    const [a, b] = bands;

    // Both lines must sit under comparable lighting for the ratio to mean
    // anything.
    const hi = Math.max(a.flankValue, b.flankValue);
    const lo = Math.min(a.flankValue, b.flankValue);
    if (hi > 0 && (hi - lo) / hi > MAX_FLANK_IMBALANCE) {
      return reject(REJECTION.UNEVEN_LIGHTING, { flankImbalance: round((hi - lo) / hi, 3) });
    }

    // The control line sits downstream of the test line, i.e. nearer the far
    // end of the result window, so it is the outer of the two.
    const axisLength = a.isVertical ? width : height;
    const distanceToEnd = (x) => Math.min(x.axisPosition, axisLength - x.axisPosition);
    if (distanceToEnd(a) <= distanceToEnd(b)) { control = a; test = b; }
    else { control = b; test = a; }
  }

  const ratio = control.signal > 0
    ? clamp((test ? test.signal : 0) / control.signal, 0, 3)
    : 0;
  const level = ratioToLevel(ratio);
  const status = statusForLevel(level);
  const shade = shadeForStatus(status);

  const controlQuality = clamp(control.chroma / 25, 0, 1);
  const geometryQuality = clamp(control.length / 40, 0, 1);
  const exposureQuality = 1 - clamp(Math.abs(control.flankValue - 180) / 120, 0, 1);
  const confidence = clamp(
    round(0.70 + 0.29 * (0.45 * controlQuality + 0.30 * geometryQuality + 0.25 * exposureQuality), 2),
    0.70,
    0.99,
  );

  return {
    valid: true,
    level,
    status,
    confidence,
    measurements: {
      shadeName: shade.name,
      shadeHex: shade.hex,
      controlIntensity: round(control.chroma, 2),
      testIntensity: round(test ? test.chroma : 0, 2),
      controlSignal: round(control.signal, 1),
      testSignal: round(test ? test.signal : 0, 1),
      ratio: round(ratio, 4),
      bandCount: bands.length,
      testLineVisible: Boolean(test),
      stripOrientation: control.isVertical ? 'horizontal' : 'vertical',
      membraneBrightness: round(control.flankValue, 1),
      controlLength: control.length,
      controlThickness: control.thickness,
    },
  };
}

/**
 * Analyse a File or a data-URL string.
 * Resolves to either the reading or a `{ valid: false, reason, message }`
 * rejection — it never throws for an unusable picture.
 */
export async function analyzeTestStrip(source) {
  if (!source) return reject(REJECTION.UNREADABLE);
  let imageData;
  try {
    const drawable = await loadDrawable(source);
    imageData = toImageData(drawable);
  } catch {
    return reject(REJECTION.UNREADABLE);
  }
  return analyzeImageData(imageData);
}
