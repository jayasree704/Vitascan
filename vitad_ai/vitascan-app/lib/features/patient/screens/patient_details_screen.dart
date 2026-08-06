import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:vitad_ai/core/theme/app_theme.dart';
import 'package:vitad_ai/core/router/app_router.dart';
import 'package:vitad_ai/features/scan/providers/scan_provider.dart';

class PatientDetailsScreen extends ConsumerStatefulWidget {
  final File? imageFile;
  const PatientDetailsScreen({super.key, this.imageFile});

  @override
  ConsumerState<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends ConsumerState<PatientDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  File? _currentImageFile;
  
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _healthConditionsCtrl = TextEditingController();
  final _collectionDateCtrl = TextEditingController(
    text: DateFormat('MM/dd/yyyy').format(DateTime.now()),
  );

  String _selectedGender = 'Male';
  String _selectedCollectionTime = 'Morning ';
  String _selectedOralIntake = 'Fasted (>8 hrs)';
  String _selectedOralHealth = 'Healthy';

  bool _isAnalyzing = false;

  final _genders = ['Male', 'Female'];
  final _collectionTimes = ['Morning ', 'Afternoon', 'Evening'];
  final _oralIntakeOptions = ['Fasted (>8 hrs)', '< 1 hour', '> 1 hour'];
  final _oralHealthOptions = ['Healthy', 'Dry Mouth', 'Recent Tooth Brushing'];

  @override
  void initState() {
    super.initState();
    _currentImageFile = widget.imageFile;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _healthConditionsCtrl.dispose();
    _collectionDateCtrl.dispose();
    super.dispose();
  }

  double get _bmi {
    final h = double.tryParse(_heightCtrl.text) ?? 0;
    final w = double.tryParse(_weightCtrl.text) ?? 0;
    if (h <= 0 || w <= 0) return 0.0;
    final hm = h / 100.0;
    return double.parse((w / (hm * hm)).toStringAsFixed(1));
  }

  Future<void> _pickNewImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (image != null && mounted) {
        setState(() {
          _currentImageFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _onCheckDetails() async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentImageFile != null) {
      setState(() => _isAnalyzing = true);
      try {
        final result = await ref.read(scanNotifierProvider.notifier).processAndAnalyzeImage(
              imageFile: _currentImageFile!,
              patientName: _nameCtrl.text.trim(),
              patientAge: int.tryParse(_ageCtrl.text.trim()),
              patientGender: _selectedGender,
            );
        if (!mounted) return;

        if (result != null) {
          context.go(AppRoutes.analysisResults, extra: result);
          return;
        }

        final scanState = ref.read(scanNotifierProvider);
        if (scanState.status == ScanStateStatus.invalidImage) {
          await _showInvalidImageDialog(scanState.message);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(scanState.message ?? 'Could not analyze the image.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error analyzing image: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isAnalyzing = false);
      }
    } else {
      context.go(AppRoutes.scan);
    }
  }

  /// Shown when the picture is not a Vitamin D test strip.
  Future<void> _showInvalidImageDialog(String? detail) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0EF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFFF3B30), size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              'Please use the correct test report',
              style: AppTextStyles.headlineMd(context).copyWith(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This image is not a Vitamin D test strip, so no result can be '
              'calculated. Capture or upload a clear photo of your Vitamin D '
              'test strip or cassette report.',
              style: AppTextStyles.bodyMd(context).copyWith(
                color: const Color(0xFF475569),
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
            if (detail != null && detail.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF0EF),
                  border: Border(
                    left: BorderSide(color: Color(0xFFFF3B30), width: 3),
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: Text(
                  detail,
                  style: AppTextStyles.bodyMd(context).copyWith(
                    color: const Color(0xFFB3261E),
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            ...[
              'Place the strip on a flat, plain background.',
              'Keep the whole result window in frame, including the C and T lines.',
              'Use bright, even light and avoid shadows or glare.',
            ].map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5, right: 8),
                      child: Icon(Icons.circle, size: 5, color: AppColors.primary),
                    ),
                    Expanded(
                      child: Text(
                        tip,
                        style: AppTextStyles.bodyMd(context).copyWith(
                          color: const Color(0xFF64748B),
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _pickNewImage();
            },
            child: const Text('Upload Another Image'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'Patient Details',
          style: AppTextStyles.headlineMd(context).copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── ANALYSIS SUBJECT ───────────────────────────────────
                  Text(
                    'ANALYSIS SUBJECT',
                    style: AppTextStyles.labelMd(context).copyWith(
                      color: AppColors.primary,
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ).animate().fadeIn(),

                  const SizedBox(height: 10),

                  // Image Subject Card
                  Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF3FC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(19),
                            child: _currentImageFile != null
                                ? Image.file(_currentImageFile!, fit: BoxFit.cover)
                                : Image.network(
                                    'https://images.unsplash.com/photo-1576086213369-97a306d36557?w=600&fit=crop',
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, _, __) => Container(
                                      color: const Color(0xFFEBF3FC),
                                      child: const Center(
                                        child: Icon(Icons.medical_services,
                                            size: 64, color: AppColors.primary),
                                      ),
                                    ),
                                  ),
                          ),
                        ),

                        // Badges Overlay Top
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'CAPTURED_SAMPLE',
                                  style: AppTextStyles.labelMd(context).copyWith(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '1080p × 800px',
                                  style: AppTextStyles.labelMd(context).copyWith(
                                    color: Colors.white,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Badge Overlay Bottom
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, color: Colors.white, size: 12),
                                const SizedBox(width: 6),
                                Text(
                                  'Captured 0 minutes ago',
                                  style: AppTextStyles.labelMd(context).copyWith(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 10),

                  // Scan Details Sub-row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Diagnostic Scan #8542',
                            style: AppTextStyles.labelMd(context).copyWith(
                              color: const Color(0xFF1E293B),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Stability: High • Lighting: Balanced',
                            style: AppTextStyles.bodyMd(context).copyWith(
                              color: const Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
                          onPressed: _pickNewImage,
                          tooltip: 'Retake or change photo',
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 150.ms),

                  const SizedBox(height: 24),

                  // ── PATIENT DETAILS SECTION ─────────────────────────────
                  Row(
                    children: [
                      const Icon(Icons.person_outline, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Patient Details',
                        style: AppTextStyles.headlineMd(context).copyWith(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 16),

                  // 1. Full Name
                  _FieldLabel(label: 'Full Name'),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: _inputDecoration(hint: 'e.g. John Doe'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ).animate().fadeIn(delay: 220.ms),

                  const SizedBox(height: 14),

                  // 2. Age & Gender Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel(label: 'Age'),
                            TextFormField(
                              controller: _ageCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration(hint: 'years'),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel(label: 'Gender'),
                            _DropdownWidget<String>(
                              value: _selectedGender,
                              items: _genders,
                              onChanged: (v) => setState(() => _selectedGender = v!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 250.ms),

                  const SizedBox(height: 14),

                  // 3. Existing Health Conditions
                  _FieldLabel(label: 'Existing Health Conditions'),
                  TextFormField(
                    controller: _healthConditionsCtrl,
                    maxLines: 3,
                    decoration: _inputDecoration(
                      hint: 'Mention chronic illnesses, allergies, or recent procedures...',
                    ),
                  ).animate().fadeIn(delay: 280.ms),

                  const SizedBox(height: 14),

                  // 4. BMI, Height (cm), Weight (kg) Row (3 Columns)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel(label: 'BMI'),
                            Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _bmi.toStringAsFixed(1),
                                style: AppTextStyles.bodyMd(context).copyWith(
                                  color: const Color(0xFF334155),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel(label: 'Height (cm)'),
                            TextFormField(
                              controller: _heightCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              decoration: _inputDecoration(hint: 'cm'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel(label: 'Weight (kg)'),
                            TextFormField(
                              controller: _weightCtrl,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              decoration: _inputDecoration(hint: 'kg'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 310.ms),

                  const SizedBox(height: 14),

                  // 5. Collection Date & Collection Time Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel(label: 'Collection Date'),
                            TextFormField(
                              controller: _collectionDateCtrl,
                              readOnly: true,
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null) {
                                  _collectionDateCtrl.text = DateFormat('MM/dd/yyyy').format(date);
                                }
                              },
                              decoration: _inputDecoration(
                                hint: 'mm/dd/yyyy',
                                suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.outline),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel(label: 'Collection Time'),
                            _DropdownWidget<String>(
                              value: _selectedCollectionTime,
                              items: _collectionTimes,
                              onChanged: (v) => setState(() => _selectedCollectionTime = v!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 340.ms),

                  const SizedBox(height: 14),

                  // 6. Prior Oral Intake & Oral Health Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel(label: 'Prior Oral Intake'),
                            _DropdownWidget<String>(
                              value: _selectedOralIntake,
                              items: _oralIntakeOptions,
                              onChanged: (v) => setState(() => _selectedOralIntake = v!),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel(label: 'Oral Health'),
                            _DropdownWidget<String>(
                              value: _selectedOralHealth,
                              items: _oralHealthOptions,
                              onChanged: (v) => setState(() => _selectedOralHealth = v!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 370.ms),

                  const SizedBox(height: 32),

                  // Sticky Primary Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isAnalyzing ? null : _onCheckDetails,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.primary.withOpacity(0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Check Details',
                            style: AppTextStyles.headlineMd(context).copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          if (_isAnalyzing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Analyzing Test Strip...',
                        style: AppTextStyles.headlineMd(context).copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Processing Vitamin D analysis for ${_nameCtrl.text}',
                        style: AppTextStyles.bodyMd(context).copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: AppTextStyles.labelMd(context).copyWith(
          color: const Color(0xFF475569),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DropdownWidget<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  const _DropdownWidget({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      onChanged: onChanged,
      isExpanded: true,
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i.toString(), overflow: TextOverflow.ellipsis))).toList(),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
      ),
      style: AppTextStyles.bodyMd(context).copyWith(color: const Color(0xFF0F172A), fontSize: 13),
      dropdownColor: Colors.white,
    );
  }
}
