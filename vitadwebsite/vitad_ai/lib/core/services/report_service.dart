import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:vitad_ai/domain/models/scan_result.dart';

/// Service responsible for generating and sharing/downloading PDF reports.
class ReportService {
  // ── Brand Colors ──────────────────────────────────────────────────────
  static const _primaryBlue = PdfColor.fromInt(0xFF0058BC);
  static const _sufficient = PdfColor.fromInt(0xFF34C759);
  static const _insufficient = PdfColor.fromInt(0xFFFF9500);
  static const _deficient = PdfColor.fromInt(0xFFFF3B30);
  static const _bgGrey = PdfColor.fromInt(0xFFF1F3FE);
  static const _textDark = PdfColor.fromInt(0xFF181C23);
  static const _textMuted = PdfColor.fromInt(0xFF414755);
  static const _divider = PdfColor.fromInt(0xFFC1C6D7);
  static const _white = PdfColors.white;

  // ── Status helpers ────────────────────────────────────────────────────
  static PdfColor _statusColor(String status) {
    switch (status) {
      case 'Sufficient':
        return _sufficient;
      case 'Insufficient':
        return _insufficient;
      default:
        return _deficient;
    }
  }

  static String _statusRange(String status) {
    switch (status) {
      case 'Sufficient':
        return '30-100 ng/mL';
      case 'Insufficient':
        return '20-30 ng/mL';
      default:
        return '< 20 ng/mL';
    }
  }

  // ── PDF Generation ───────────────────────────────────────────────────
  Future<Uint8List> _generatePdfBytes(ScanResult result) async {
    final pdf = pw.Document(
      author: 'VitaD AI',
      title: 'Vitamin D Analysis Report',
      subject: 'AI-powered Vitamin D test strip analysis',
    );

    final statusColor = _statusColor(result.status);
    final dateStr = DateFormat('MMMM d, yyyy').format(result.createdAt);
    final timeStr = DateFormat('hh:mm a').format(result.createdAt);
    final confidencePct =
        '${(result.aiConfidence * 100).toStringAsFixed(0)}%';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        build: (pw.Context context) => [
          // ── Header ────────────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: pw.BoxDecoration(
              color: _primaryBlue,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'VitaD AI',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: _white,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Vitamin D Analysis Report',
                      style: pw.TextStyle(fontSize: 11, color: _white),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      dateStr,
                      style: pw.TextStyle(
                          fontSize: 10,
                          color: _white,
                          fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      timeStr,
                      style: pw.TextStyle(fontSize: 9, color: _white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // ── Patient Info ──────────────────────────────────────────────
          if (result.patientName != null && result.patientName!.isNotEmpty) ...[
            _sectionLabel('Patient Information'),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: _bgGrey,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                children: [
                  _infoChip('Name', result.patientName!),
                  pw.SizedBox(width: 20),
                  if (result.patientAge != null)
                    _infoChip('Age', '${result.patientAge} yrs'),
                  if (result.patientAge != null) pw.SizedBox(width: 20),
                  if (result.patientGender != null)
                    _infoChip('Gender', result.patientGender!),
                ],
              ),
            ),
            pw.SizedBox(height: 18),
          ],

          // ── Result Card ───────────────────────────────────────────────
          _sectionLabel('Vitamin D Result'),
          pw.SizedBox(height: 8),
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: statusColor, width: 1.5),
              color: _white,
              borderRadius: pw.BorderRadius.circular(10),
              boxShadow: [
                pw.BoxShadow(
                  color: PdfColors.grey300,
                  offset: const PdfPoint(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            padding: const pw.EdgeInsets.all(16),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Big level value
                pw.Container(
                  width: 90,
                  height: 90,
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex(
                        statusColor == _sufficient
                            ? '#E8F9EC'
                            : statusColor == _insufficient
                                ? '#FFF3E0'
                                : '#FFEBEA'),
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Center(
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Text(
                          result.vitaminDLevel.toStringAsFixed(1),
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        pw.Text(
                          'ng/mL',
                          style: pw.TextStyle(
                              fontSize: 9, color: _textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex(
                              statusColor == _sufficient
                                  ? '#E8F9EC'
                                  : statusColor == _insufficient
                                      ? '#FFF3E0'
                                      : '#FFEBEA'),
                          borderRadius: pw.BorderRadius.circular(999),
                        ),
                        child: pw.Text(
                          result.status,
                          style: pw.TextStyle(
                            color: statusColor,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Reference range: ${_statusRange(result.status)}',
                        style:
                            pw.TextStyle(fontSize: 10, color: _textMuted),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'AI Confidence: $confidencePct',
                        style:
                            pw.TextStyle(fontSize: 10, color: _textMuted),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        result.status == 'Sufficient'
                            ? 'Your Vitamin D levels are within the optimal clinical range.'
                            : 'Your Vitamin D levels are below the optimal clinical range of 30-100 ng/mL.',
                        style: pw.TextStyle(
                            fontSize: 10,
                            color: _textDark,
                            lineSpacing: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // ── Food Recommendations ──────────────────────────────────────
          if (result.recommendations.isNotEmpty) ...[
            _sectionLabel('Personalized Food Recommendations'),
            pw.SizedBox(height: 8),
            pw.GridView(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.8,
              children: result.recommendations.map((food) {
                return pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: _bgGrey,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: _divider, width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (food.category != null)
                        pw.Text(
                          food.category!.toUpperCase(),
                          style: pw.TextStyle(
                              fontSize: 7,
                              color: _primaryBlue,
                              fontWeight: pw.FontWeight.bold),
                        ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        food.name,
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: _textDark),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        food.description,
                        style: pw.TextStyle(
                            fontSize: 8, color: _textMuted, lineSpacing: 1.3),
                        maxLines: 3,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            pw.SizedBox(height: 20),
          ],

          // ── Lifestyle Tips ────────────────────────────────────────────
          if (result.lifestyleTips.isNotEmpty) ...[
            _sectionLabel('Lifestyle Improvements'),
            pw.SizedBox(height: 8),
            ...result.lifestyleTips.asMap().entries.map((entry) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 22,
                      height: 22,
                      decoration: pw.BoxDecoration(
                        color: _primaryBlue,
                        shape: pw.BoxShape.circle,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          '${entry.key + 1}',
                          style: pw.TextStyle(
                              fontSize: 10,
                              color: _white,
                              fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          color: _bgGrey,
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Text(
                          entry.value,
                          style: pw.TextStyle(
                              fontSize: 10,
                              color: _textDark,
                              lineSpacing: 1.4),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 20),
          ],

          // ── Divider ───────────────────────────────────────────────────
          pw.Divider(color: _divider, thickness: 0.5),
          pw.SizedBox(height: 10),

          // ── Disclaimer ────────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#FFF8E1'),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(
                  color: PdfColor.fromHex('#FFE082'), width: 0.5),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('[!] ',
                    style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColor.fromHex('#F57F17'))),
                pw.Expanded(
                  child: pw.Text(
                    'DISCLAIMER: This report is generated by an AI system for informational purposes only. '
                    'It does not constitute medical advice. Please consult a qualified healthcare professional '
                    'before making any health decisions based on these results.',
                    style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColor.fromHex('#6D4C41'),
                        lineSpacing: 1.4),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          // ── Footer ────────────────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated by VitaD AI - ${DateFormat('MMM d, yyyy - hh:mm a').format(result.createdAt)}',
                style: pw.TextStyle(fontSize: 8, color: _textMuted),
              ),
              pw.Text(
                'vitad-ai.app',
                style: pw.TextStyle(
                    fontSize: 8,
                    color: _primaryBlue,
                    fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ── Helper widgets ───────────────────────────────────────────────────
  static pw.Widget _sectionLabel(String text) {
    return pw.Row(
      children: [
        pw.Container(
          width: 3,
          height: 14,
          color: _primaryBlue,
          margin: const pw.EdgeInsets.only(right: 8),
        ),
        pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: _textDark,
          ),
        ),
      ],
    );
  }

  static pw.Widget _infoChip(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style: pw.TextStyle(fontSize: 8, color: _textMuted)),
        pw.SizedBox(height: 2),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: _textDark)),
      ],
    );
  }

  // ── Public API ───────────────────────────────────────────────────────

  /// Saves the report PDF to the device's public Downloads/Documents directory.
  /// Returns the saved [File].
  Future<File> downloadReport(ScanResult result) async {
    final bytes = await _generatePdfBytes(result);
    Directory dir;
    if (Platform.isAndroid) {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        dir = downloadDir;
      } else {
        dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      }
    } else {
      dir = await getApplicationDocumentsDirectory();
    }
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(result.createdAt);
    final patientSlug = (result.patientName ?? 'report')
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_');
    final fileName = 'vitad_${patientSlug}_$timestamp.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Shares the report PDF via the native OS share sheet.
  Future<void> shareReport(ScanResult result) async {
    final bytes = await _generatePdfBytes(result);
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(result.createdAt);
    final patientSlug = (result.patientName ?? 'report')
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_');
    final fileName = 'vitad_${patientSlug}_$timestamp.pdf';

    // Write to temp directory for sharing
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf', name: fileName)],
      subject: 'VitaD AI – Vitamin D Analysis Report',
      text: 'My Vitamin D Analysis Report from VitaD AI\n'
          'Level: ${result.vitaminDLevel.toStringAsFixed(1)} ng/mL – ${result.status}',
    );
  }
}
