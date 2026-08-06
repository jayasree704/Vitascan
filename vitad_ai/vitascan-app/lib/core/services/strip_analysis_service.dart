import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../domain/models/scan_result.dart';
import 'recommendation_service.dart';
import 'strip_analysis.dart';

/// Raised when the uploaded picture is not a readable Vitamin D test strip.
/// The UI turns this into the "use the correct test report" dialog.
class InvalidTestImageException implements Exception {
  final StripRejection reason;
  final String message;

  const InvalidTestImageException(this.reason, this.message);

  @override
  String toString() => message;
}

/// Reads a Vitamin D test strip photo entirely on-device: no AI service and
/// no network call. See [analyzeStripBytes] for the measurement itself.
class StripAnalysisService {
  const StripAnalysisService();

  Future<ScanResult> analyzeTestStripImage({
    required File imageFile,
    required String userId,
    String? imageUrl,
  }) async {
    final Uint8List bytes;
    try {
      bytes = await imageFile.readAsBytes();
    } catch (_) {
      throw const InvalidTestImageException(
        StripRejection.unreadable,
        'The selected file could not be opened.',
      );
    }

    // Decoding a full-resolution camera photo is slow, so keep it off the UI
    // thread.
    final analysis = await compute(analyzeStripBytes, bytes);

    if (!analysis.isValid) {
      throw InvalidTestImageException(
        analysis.rejection ?? StripRejection.noStrip,
        analysis.message,
      );
    }

    return ScanResult(
      userId: userId,
      imageUrl: imageUrl,
      vitaminDLevel: analysis.level,
      status: analysis.status,
      aiConfidence: analysis.confidence,
      aiRawResponse: analysis.summary,
      recommendations: RecommendationService.foodsFor(analysis.status),
      lifestyleTips: RecommendationService.tipsFor(analysis.status),
      createdAt: DateTime.now(),
    );
  }
}
