/**
 * reportUtils.js
 * Generates a styled PDF report for a VitaScan Vitamin D result.
 * Uses jsPDF for PDF generation (no html2canvas dependency needed).
 */
import jsPDF from 'jspdf';

function statusColor(level) {
  if (level < 20) return [255, 59, 48];
  if (level < 30) return [255, 149, 0];
  return [52, 199, 89];
}

function statusLabel(level) {
  if (level < 20) return 'Deficient';
  if (level < 30) return 'Insufficient';
  return 'Sufficient';
}

function statusDesc(level) {
  if (level < 20) return 'Critically low. Immediate supplementation recommended.';
  if (level < 30) return 'Below optimal range. Lifestyle changes & supplementation advised.';
  return 'Within healthy clinical range of 30–100 ng/mL.';
}

function fmtDate(dt) {
  return new Date(dt).toLocaleDateString('en-US', {
    month: 'long', day: 'numeric', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  });
}

/**
 * Build and download a PDF report for a scan result.
 * @param {object} scan - The scan result object from Supabase / AI analysis.
 */
export function downloadReportPDF(scan) {
  const doc = new jsPDF({ unit: 'pt', format: 'a4' });
  const PW = doc.internal.pageSize.getWidth();   // 595
  const PH = doc.internal.pageSize.getHeight();  // 842

  const level = scan.vitamin_d_level ?? 0;
  const col = statusColor(level);   // RGB array
  const status = scan.status || statusLabel(level);
  const hexCol = `#${col.map(c => c.toString(16).padStart(2, '0')).join('')}`;

  /* ── Background ── */
  doc.setFillColor(249, 249, 255);
  doc.rect(0, 0, PW, PH, 'F');

  /* ── Header bar ── */
  doc.setFillColor(0, 88, 188);
  doc.roundedRect(0, 0, PW, 90, 0, 0, 'F');

  // Logo pill
  doc.setFillColor(255, 255, 255, 0.15);
  doc.setTextColor(255, 255, 255);
  doc.setFontSize(22);
  doc.setFont('helvetica', 'bold');
  doc.text('💊 VitaScan', 36, 42);

  doc.setFontSize(11);
  doc.setFont('helvetica', 'normal');
  doc.text('Vitamin D Health Report', 36, 62);

  // Report date (right-aligned)
  doc.setFontSize(9);
  doc.text(`Generated: ${fmtDate(scan.created_at || new Date())}`, PW - 36, 62, { align: 'right' });

  /* ── Level Hero Card ── */
  doc.setFillColor(255, 255, 255);
  doc.roundedRect(36, 108, PW - 72, 110, 12, 12, 'F');
  // Color accent bar (left)
  doc.setFillColor(...col);
  doc.roundedRect(36, 108, 6, 110, 3, 3, 'F');

  // Big level number
  doc.setTextColor(...col);
  doc.setFontSize(52);
  doc.setFont('helvetica', 'bold');
  doc.text(`${level.toFixed(1)}`, 66, 168);

  // Unit label
  doc.setFontSize(13);
  doc.setFont('helvetica', 'normal');
  doc.setTextColor(113, 119, 134);
  doc.text('ng/mL', 68, 190);

  // Status badge
  doc.setFillColor(...col.map(c => Math.min(255, c + 190)));
  doc.roundedRect(200, 126, 90, 26, 6, 6, 'F');
  doc.setTextColor(...col);
  doc.setFontSize(11);
  doc.setFont('helvetica', 'bold');
  doc.text(status, 245, 143, { align: 'center' });

  // Description
  doc.setTextColor(65, 71, 85);
  doc.setFontSize(10);
  doc.setFont('helvetica', 'normal');
  const descLines = doc.splitTextToSize(statusDesc(level), PW - 270);
  doc.text(descLines, 200, 168);

  /* ── Patient Info Card ── */
  let y = 242;
  doc.setFillColor(255, 255, 255);
  doc.roundedRect(36, y, PW - 72, 130, 12, 12, 'F');

  doc.setFontSize(12);
  doc.setFont('helvetica', 'bold');
  doc.setTextColor(0, 88, 188);
  doc.text('Patient Information', 56, y + 24);

  doc.setDrawColor(193, 198, 215);
  doc.setLineWidth(0.5);
  doc.line(56, y + 32, PW - 56, y + 32);

  const rows = [
    ['Patient Name', scan.patient_name || '—'],
    ['Age', scan.patient_age ? `${scan.patient_age} years` : '—'],
    ['Gender', scan.patient_gender || '—'],
    ['AI Confidence', `${Math.round((scan.ai_confidence || 0.94) * 100)}%`],
    ['Test Date', fmtDate(scan.created_at || new Date())],
  ];

  doc.setFontSize(10);
  rows.forEach(([label, val], i) => {
    const ry = y + 46 + i * 20;
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(113, 119, 134);
    doc.text(label, 56, ry);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(24, 28, 35);
    doc.text(val, 220, ry);
  });

  /* ── Reference Ranges ── */
  y = 400;
  doc.setFillColor(255, 255, 255);
  doc.roundedRect(36, y, PW - 72, 130, 12, 12, 'F');

  doc.setFontSize(12);
  doc.setFont('helvetica', 'bold');
  doc.setTextColor(0, 88, 188);
  doc.text('Reference Ranges', 56, y + 24);

  doc.setLineWidth(0.5);
  doc.setDrawColor(193, 198, 215);
  doc.line(56, y + 32, PW - 56, y + 32);

  const refRanges = [
    { label: 'Deficient', range: '< 20 ng/mL', col: [255, 59, 48] },
    { label: 'Insufficient', range: '20 – 30 ng/mL', col: [255, 149, 0] },
    { label: 'Sufficient', range: '30 – 100 ng/mL', col: [52, 199, 89] },
    { label: 'Toxic', range: '> 100 ng/mL', col: [186, 26, 26] },
  ];

  refRanges.forEach((r, i) => {
    const rx = 56 + i * 130;
    const ry = y + 50;
    doc.setFillColor(...r.col.map(c => Math.min(255, c + 180)));
    doc.roundedRect(rx, ry, 112, 56, 8, 8, 'F');
    doc.setFontSize(10);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(...r.col);
    doc.text(r.label, rx + 56, ry + 20, { align: 'center' });
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(9);
    doc.text(r.range, rx + 56, ry + 36, { align: 'center' });
  });

  /* ── Lifestyle Tips ── */
  const tips = Array.isArray(scan.lifestyle_tips) ? scan.lifestyle_tips : [];
  if (tips.length > 0) {
    y = 558;
    doc.setFillColor(255, 255, 255);
    const tipsH = 50 + tips.length * 28;
    doc.roundedRect(36, y, PW - 72, tipsH, 12, 12, 'F');

    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(0, 88, 188);
    doc.text('Lifestyle Tips', 56, y + 24);

    doc.setLineWidth(0.5);
    doc.setDrawColor(193, 198, 215);
    doc.line(56, y + 32, PW - 56, y + 32);

    tips.forEach((tip, i) => {
      const ty = y + 48 + i * 26;
      // bullet dot
      doc.setFillColor(52, 199, 89);
      doc.circle(64, ty - 4, 3, 'F');
      doc.setFontSize(10);
      doc.setFont('helvetica', 'normal');
      doc.setTextColor(65, 71, 85);
      const tipLines = doc.splitTextToSize(tip, PW - 130);
      doc.text(tipLines, 74, ty);
    });

    y += tipsH + 16;
  }

  /* ── Footer ── */
  doc.setFillColor(0, 88, 188);
  doc.rect(0, PH - 44, PW, 44, 'F');
  doc.setFontSize(9);
  doc.setFont('helvetica', 'normal');
  doc.setTextColor(255, 255, 255);
  doc.text('This report is for informational purposes only. Consult a healthcare professional for medical advice.', PW / 2, PH - 22, { align: 'center' });
  doc.setFontSize(8);
  doc.setTextColor(173, 198, 255);
  doc.text('VitaScan · AI-Powered Vitamin D Analysis', PW / 2, PH - 10, { align: 'center' });

  /* ── Save ── */
  const safeName = (scan.patient_name || 'patient').replace(/\s+/g, '_');
  const dateStr = new Date(scan.created_at || Date.now()).toISOString().slice(0, 10);
  doc.save(`VitaScan_Report_${safeName}_${dateStr}.pdf`);
}

/**
 * Build a share text for WhatsApp / clipboard sharing.
 * @param {object} scan
 * @returns {string}
 */
export function buildShareText(scan) {
  const level = scan.vitamin_d_level ?? 0;
  const status = scan.status || statusLabel(level);
  const name = scan.patient_name || 'Patient';
  const date = new Date(scan.created_at || Date.now()).toLocaleDateString('en-US', {
    month: 'short', day: 'numeric', year: 'numeric',
  });

  let emoji = '🟢';
  if (level < 20) emoji = '🔴';
  else if (level < 30) emoji = '🟡';

  const tips = Array.isArray(scan.lifestyle_tips) && scan.lifestyle_tips.length > 0
    ? `\n\n💡 *Tips:*\n${scan.lifestyle_tips.slice(0, 2).map(t => `• ${t}`).join('\n')}`
    : '';

  return `${emoji} *VitaScan Vitamin D Report*\n\n` +
    `👤 Patient: ${name}\n` +
    `📊 Level: ${level.toFixed(1)} ng/mL\n` +
    `📋 Status: ${status}\n` +
    `📅 Date: ${date}${tips}\n\n` +
    `_Analyzed by VitaScan AI · For informational use only_`;
}
