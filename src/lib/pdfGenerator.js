import { jsPDF } from 'jspdf';
import toast from 'react-hot-toast';

export function downloadReportPDF(scan) {
  try {
    const doc = new jsPDF();
    const name = scan.patient_name || 'Patient';
    const level = scan.vitamin_d_level != null ? Number(scan.vitamin_d_level).toFixed(1) : '0.0';
    const status = scan.status || (level < 20 ? 'Deficient' : level < 30 ? 'Insufficient' : 'Sufficient');
    const dateStr = scan.created_at ? new Date(scan.created_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) : new Date().toLocaleDateString();
    const confidence = ((scan.ai_confidence || 0.94) * 100).toFixed(0);

    // Color definitions
    let primaryColor = [190, 24, 93]; // Dark Pink for Sufficient (#BE185D)
    if (level < 20) primaryColor = [244, 114, 182]; // Pale Pink for Deficient (#F472B6)
    else if (level < 30) primaryColor = [236, 72, 153]; // Light Pink for Insufficient (#EC4899)

    // Header Background
    doc.setFillColor(15, 23, 42); // Navy background
    doc.rect(0, 0, 210, 40, 'F');

    // Header Title
    doc.setTextColor(255, 255, 255);
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(22);
    doc.text('VitaScan Diagnostic Report', 14, 22);

    doc.setFontSize(10);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(203, 213, 225);
    doc.text('Automated Vitamin D Densitometry & Clinical Analysis', 14, 30);

    // Date in top right
    doc.text(`Date: ${dateStr}`, 196, 22, { align: 'right' });

    // Section 1: Patient Information Card
    doc.setFillColor(248, 250, 252);
    doc.roundedRect(14, 48, 182, 38, 3, 3, 'F');

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(11);
    doc.setTextColor(30, 41, 59);
    doc.text('PATIENT DEMOGRAPHICS', 20, 58);

    doc.setFontSize(10);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(71, 85, 105);

    doc.text(`Patient Name:`, 20, 68);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(15, 23, 42);
    doc.text(`${name}`, 50, 68);

    doc.setFont('helvetica', 'normal');
    doc.setTextColor(71, 85, 105);
    doc.text(`Age:`, 20, 78);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(15, 23, 42);
    doc.text(`${scan.patient_age ? `${scan.patient_age} yrs` : 'N/A'}`, 50, 78);

    doc.setFont('helvetica', 'normal');
    doc.setTextColor(71, 85, 105);
    doc.text(`Gender:`, 110, 68);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(15, 23, 42);
    doc.text(`${scan.patient_gender || 'N/A'}`, 135, 68);

    doc.setFont('helvetica', 'normal');
    doc.setTextColor(71, 85, 105);
    doc.text(`AI Confidence:`, 110, 78);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(15, 23, 42);
    doc.text(`${confidence}%`, 135, 78);

    // Section 2: Vitamin D Diagnostic Result Box
    doc.setFillColor(...primaryColor);
    doc.roundedRect(14, 94, 182, 45, 4, 4, 'F');

    doc.setTextColor(255, 255, 255);
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(12);
    doc.text('MEASURED VITAMIN D (25-OH-D) LEVEL', 22, 106);

    doc.setFontSize(32);
    doc.text(`${level}`, 22, 126);

    doc.setFontSize(14);
    doc.text('ng/mL', 75, 126);

    // Status Pill
    doc.setFillColor(255, 255, 255);
    doc.roundedRect(125, 106, 60, 18, 9, 9, 'F');
    doc.setTextColor(...primaryColor);
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.text(`${status.toUpperCase()}`, 155, 118, { align: 'center' });

    // Section 3: Clinical Range Reference Guide
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(12);
    doc.setTextColor(15, 23, 42);
    doc.text('CLINICAL RANGE GUIDE', 14, 152);

    doc.setLineWidth(0.5);
    doc.setDrawColor(226, 232, 240);

    // Deficient
    doc.setFillColor(253, 242, 248);
    doc.roundedRect(14, 158, 56, 24, 3, 3, 'FD');
    doc.setTextColor(244, 114, 182);
    doc.setFontSize(10);
    doc.text('Deficient (< 20)', 18, 166);
    doc.setFontSize(8);
    doc.setTextColor(100, 116, 139);
    doc.text('Critically low levels', 18, 175);

    // Insufficient
    doc.setFillColor(252, 231, 243);
    doc.roundedRect(77, 158, 56, 24, 3, 3, 'FD');
    doc.setTextColor(236, 72, 153);
    doc.setFontSize(10);
    doc.text('Insufficient (20-30)', 81, 166);
    doc.setFontSize(8);
    doc.setTextColor(100, 116, 139);
    doc.text('Below optimal range', 81, 175);

    // Sufficient
    doc.setFillColor(251, 207, 232);
    doc.roundedRect(140, 158, 56, 24, 3, 3, 'FD');
    doc.setTextColor(190, 24, 93);
    doc.setFontSize(10);
    doc.text('Sufficient (30-100)', 144, 166);
    doc.setFontSize(8);
    doc.setTextColor(100, 116, 139);
    doc.text('Healthy clinical range', 144, 175);

    // Section 4: Lifestyle Tips & Recommendations
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(12);
    doc.setTextColor(15, 23, 42);
    doc.text('RECOMMENDED LIFESTYLE ACTIONS', 14, 196);

    const tips = scan.lifestyle_tips && scan.lifestyle_tips.length > 0 ? scan.lifestyle_tips : [
      'Expose arms and legs to direct sunlight for 15-20 minutes daily.',
      'Pair Vitamin D rich foods (fatty fish, eggs, milk) with healthy fats.',
      'Retest your levels in 8-12 weeks to monitor diagnostic progress.'
    ];

    let currentY = 206;
    tips.forEach((tip, idx) => {
      doc.setFillColor(241, 245, 249);
      doc.roundedRect(14, currentY, 182, 14, 2, 2, 'F');
      doc.setTextColor(30, 41, 59);
      doc.setFont('helvetica', 'normal');
      doc.setFontSize(9.5);
      doc.text(`• ${tip}`, 20, currentY + 9);
      currentY += 18;
    });

    // Disclaimer Footer
    doc.setFontSize(8);
    doc.setTextColor(148, 163, 184);
    doc.text('Disclaimer: VitaScan quantitative densitometry is intended for screening and educational purposes.', 105, 280, { align: 'center' });
    doc.text('Generated by VitaScan Medical Suite · https://vitascan.app', 105, 285, { align: 'center' });

    const fileName = `VitaScan_Report_${name.replace(/[^a-zA-Z0-9]/g, '_')}.pdf`;
    doc.save(fileName);
    toast.success(`Downloaded ${fileName}`);
  } catch (err) {
    console.error('PDF Generation Error:', err);
    toast.error('Failed to generate PDF report: ' + err.message);
  }
}

export function shareReport(scan) {
  const name = scan.patient_name || 'Patient';
  const level = scan.vitamin_d_level != null ? Number(scan.vitamin_d_level).toFixed(1) : '0.0';
  const status = scan.status || (level < 20 ? 'Deficient' : level < 30 ? 'Insufficient' : 'Sufficient');
  const dateStr = scan.created_at ? new Date(scan.created_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) : new Date().toLocaleDateString();

  const summaryText = `🧪 VitaScan Vitamin D Diagnostic Report:\nPatient: ${name}\nVitamin D Level: ${level} ng/mL (${status})\nDate: ${dateStr}`;

  if (navigator.share) {
    navigator.share({
      title: `VitaScan Report - ${name}`,
      text: summaryText,
      url: window.location.href,
    }).catch(() => {});
  } else {
    navigator.clipboard.writeText(summaryText);
    toast.success('Report summary copied to clipboard!');
  }
}
