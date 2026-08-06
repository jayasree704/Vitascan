import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/strip_analysis_service.dart';
import '../../../domain/models/scan_result.dart';
import '../../auth/providers/auth_provider.dart';
import '../../history/providers/history_provider.dart';

final stripAnalysisServiceProvider = Provider<StripAnalysisService>((ref) {
  return const StripAnalysisService();
});

enum ScanStateStatus { initial, uploading, analyzing, success, error, invalidImage }

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

  Future<ScanResult?> processAndAnalyzeImage({
    required File imageFile,
    String? patientName,
    int? patientAge,
    String? patientGender,
  }) async {
    state = state.copyWith(
      status: ScanStateStatus.analyzing,
      message: 'Measuring the control and test lines...',
    );

    final currentUser = _ref.read(currentUserProvider);
    final userId = currentUser?.id ?? 'guest_user';

    final supabaseService = _ref.read(supabaseServiceProvider);
    final analysisService = _ref.read(stripAnalysisServiceProvider);

    try {
      // Step 1: Read the strip locally. Done before uploading so a picture
      // that is not a test strip never leaves the device.
      final rawResult = await analysisService.analyzeTestStripImage(
        imageFile: imageFile,
        userId: userId,
      );

      // Step 2: Upload the verified strip image to Supabase Storage
      state = state.copyWith(
        status: ScanStateStatus.uploading,
        message: 'Uploading test strip image...',
      );

      String? imageUrl;
      try {
        imageUrl = await supabaseService.uploadScanImage(imageFile, userId);
      } catch (_) {
        // A failed upload must not discard a valid reading.
      }

      // Attach patient details to the scan result
      final scanResult = ScanResult(
        id: rawResult.id,
        userId: rawResult.userId,
        patientName: patientName,
        patientAge: patientAge,
        patientGender: patientGender,
        imageUrl: imageUrl,
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

      // Invalidate history provider so it re-fetches from Supabase
      _ref.invalidate(scanHistoryProvider);

      state = state.copyWith(
        status: ScanStateStatus.success,
        result: finalResult,
      );

      return finalResult;
    } on InvalidTestImageException catch (e) {
      // Not a Vitamin D test strip — the screen shows a dialog for this.
      state = state.copyWith(
        status: ScanStateStatus.invalidImage,
        message: e.message,
      );
      return null;
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
