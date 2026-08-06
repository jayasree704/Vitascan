import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/test_strip_analyzer_service.dart';
import '../../../domain/models/scan_result.dart';
import '../../auth/providers/auth_provider.dart';
import '../../history/providers/history_provider.dart';

final testStripAnalyzerServiceProvider = Provider<TestStripAnalyzerService>((ref) {
  return TestStripAnalyzerService();
});

enum ScanStateStatus { initial, uploading, analyzing, success, error }

class ScanState {
  final ScanStateStatus status;
  final String? message;
  final ScanResult? result;

  const ScanState({
    this.status = ScanStateStatus.initial,
    this.message,
    this.result,
  });

  ScanState copyWith({
    ScanStateStatus? status,
    String? message,
    ScanResult? result,
  }) {
    return ScanState(
      status: status ?? this.status,
      message: message ?? this.message,
      result: result ?? this.result,
    );
  }
}

class ScanNotifier extends StateNotifier<ScanState> {
  final Ref _ref;

  ScanNotifier(this._ref) : super(const ScanState());

  /// Validates whether the image is a valid Vitamin D test strip
  Future<TestStripValidationResult> validateTestStripImage(File imageFile) async {
    final analyzerService = _ref.read(testStripAnalyzerServiceProvider);
    return await analyzerService.validateImage(imageFile);
  }

  Future<ScanResult?> processAndAnalyzeImage({
    required File imageFile,
    String? patientName,
    int? patientAge,
    String? patientGender,
  }) async {
    state = state.copyWith(
      status: ScanStateStatus.uploading,
      message: 'Uploading test strip image...',
    );

    final currentUser = _ref.read(currentUserProvider);
    final userId = currentUser?.id ?? 'guest_user';

    final supabaseService = _ref.read(supabaseServiceProvider);
    final analyzerService = _ref.read(testStripAnalyzerServiceProvider);

    try {
      // Step 1: Upload image to Supabase Storage (if connected)
      final imageUrl = await supabaseService.uploadScanImage(imageFile, userId);

      state = state.copyWith(
        status: ScanStateStatus.analyzing,
        message: 'Analyzing test strip image for Vitamin D levels...',
      );

      // Step 2: Analyze image with custom image processing backend
      final rawResult = await analyzerService.analyzeTestStripImage(
        imageFile: imageFile,
        userId: userId,
        imageUrl: imageUrl,
      );

      // Attach patient details to the scan result
      final scanResult = ScanResult(
        id: rawResult.id,
        userId: rawResult.userId,
        patientName: patientName,
        patientAge: patientAge,
        patientGender: patientGender,
        imageUrl: rawResult.imageUrl,
        vitaminDLevel: rawResult.vitaminDLevel,
        status: rawResult.status,
        aiConfidence: rawResult.aiConfidence,
        aiRawResponse: rawResult.aiRawResponse,
        recommendations: rawResult.recommendations,
        lifestyleTips: rawResult.lifestyleTips,
        createdAt: rawResult.createdAt,
      );

      // Step 3: Save result to Supabase Database
      ScanResult finalResult = scanResult;
      try {
        finalResult = await supabaseService.saveScanResult(scanResult);
      } catch (_) {
        // Fallback for offline or guest usage
      }

      // Invalidate history provider so it re-fetches
      _ref.invalidate(scanHistoryProvider);

      state = state.copyWith(
        status: ScanStateStatus.success,
        result: finalResult,
      );

      return finalResult;
    } catch (e) {
      state = state.copyWith(
        status: ScanStateStatus.error,
        message: 'Failed to analyze test strip: $e',
      );
      return null;
    }
  }

  void reset() {
    state = const ScanState();
  }
}

final scanNotifierProvider =
    StateNotifierProvider<ScanNotifier, ScanState>((ref) {
  return ScanNotifier(ref);
});

