import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vitad_ai/core/theme/app_theme.dart';
import 'package:vitad_ai/core/router/app_router.dart';
import 'package:vitad_ai/features/scan/providers/scan_provider.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _showInvalidImageDialog(String customMessage) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFDC2626),
                size: 44,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Invalid Test Strip Image',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: Text(
          'This image does not belong to a test result for Vitamin D. Please use a correct image of a test strip.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Use Correct Image',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processImage(File imageFile) async {
    if (!mounted) return;

    final validation = await ref
        .read(scanNotifierProvider.notifier)
        .validateTestStripImage(imageFile);

    if (!validation.isValid && mounted) {
      await _showInvalidImageDialog(validation.message);
      return;
    }

    if (mounted) {
      context.go(AppRoutes.patientDetails, extra: imageFile);
    }
  }

  Future<void> _captureFromCamera() async {
    try {
      final XFile? photo =
          await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
      if (photo != null && mounted) {
        await _processImage(File(photo.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image =
          await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (image != null && mounted) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanNotifierProvider);
    final isProcessing = scanState.status == ScanStateStatus.uploading ||
        scanState.status == ScanStateStatus.analyzing;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Scan Test Strip'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _ScanFrame(isProcessing: isProcessing, message: scanState.message)
                .animate()
                .fadeIn(delay: 100.ms),

            const SizedBox(height: 32),

            _ScanInstructions().animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 32),

            _CaptureButtons(
              isProcessing: isProcessing,
              onCamera: _captureFromCamera,
              onGallery: _pickFromGallery,
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  final bool isProcessing;
  final String? message;

  const _ScanFrame({required this.isProcessing, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isProcessing ? AppColors.primary : AppColors.primary.withValues(alpha: 0.4),
          width: isProcessing ? 3 : 2,
        ),
      ),
      child: Stack(
        children: [
          ..._buildCornerMarkers(),
          Center(
            child: isProcessing
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        message ?? 'AI Analyzing Image...',
                        style: AppTextStyles.headlineMd(context).copyWith(
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.crop_free,
                            size: 48, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Position test strip here',
                        style: AppTextStyles.headlineMd(context)
                            .copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ensure the strip is fully visible\nand well-lit',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMd(context)
                            .copyWith(color: AppColors.outline, fontSize: 13),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerMarkers() {
    return [
      _corner(top: 12, left: 12, topBorder: true, leftBorder: true),
      _corner(top: 12, right: 12, topBorder: true, rightBorder: true),
      _corner(bottom: 12, left: 12, bottomBorder: true, leftBorder: true),
      _corner(bottom: 12, right: 12, bottomBorder: true, rightBorder: true),
    ];
  }

  Widget _corner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    bool topBorder = false,
    bool bottomBorder = false,
    bool leftBorder = false,
    bool rightBorder = false,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          border: Border(
            top: topBorder
                ? const BorderSide(color: AppColors.primary, width: 3)
                : BorderSide.none,
            bottom: bottomBorder
                ? const BorderSide(color: AppColors.primary, width: 3)
                : BorderSide.none,
            left: leftBorder
                ? const BorderSide(color: AppColors.primary, width: 3)
                : BorderSide.none,
            right: rightBorder
                ? const BorderSide(color: AppColors.primary, width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _ScanInstructions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      (Icons.light_mode_outlined, 'Good Lighting', 'Use natural or bright indoor light'),
      (Icons.crop_outlined, 'Full Strip Visible', 'Include both control and test lines'),
      (Icons.do_not_touch_outlined, 'Hold Steady', 'Keep camera still for a clear image'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SCAN INSTRUCTIONS',
          style: AppTextStyles.labelMd(context)
              .copyWith(color: AppColors.primary, letterSpacing: 1.2),
        ),
        const SizedBox(height: 12),
        ...steps.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(s.$1, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.$2,
                          style: AppTextStyles.labelMd(context)
                              .copyWith(color: AppColors.onSurface, fontSize: 14)),
                      Text(s.$3,
                          style: AppTextStyles.bodyMd(context).copyWith(
                              color: AppColors.onSurfaceVariant, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CaptureButtons extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _CaptureButtons({
    required this.isProcessing,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: isProcessing ? null : onCamera,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: isProcessing
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.camera_alt, color: Colors.white, size: 36),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Tap to capture test strip',
          style: AppTextStyles.labelMd(context)
              .copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: isProcessing ? null : onGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Upload from Gallery'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.outlineVariant, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              foregroundColor: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
