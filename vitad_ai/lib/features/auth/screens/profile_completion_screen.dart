import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vitad_ai/core/theme/app_theme.dart';
import 'package:vitad_ai/core/router/app_router.dart';
import 'package:vitad_ai/core/services/supabase_service.dart';
import 'package:vitad_ai/domain/models/user_profile.dart';
import 'package:vitad_ai/features/auth/providers/auth_provider.dart';

class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState
    extends ConsumerState<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedDob;
  bool _isSaving = false;

  final _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

  @override
  void dispose() {
    _ageCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(now.year - 120),
      lastDate: DateTime(now.year - 1),
      helpText: 'Select Date of Birth',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobCtrl.text = DateFormat('dd MMM yyyy').format(picked);
        // Auto-fill age from DOB
        final age = now.year -
            picked.year -
            (now.month < picked.month ||
                    (now.month == picked.month && now.day < picked.day)
                ? 1
                : 0);
        _ageCtrl.text = age.toString();
      });
    }
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gender')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final supabaseService = ref.read(supabaseServiceProvider);
        final existing = await supabaseService.fetchProfile(user.id);
        await supabaseService.createOrUpdateProfile(
          UserProfile(
            id: user.id,
            fullName: existing?.fullName ??
                user.userMetadata?['full_name'] as String? ??
                user.email?.split('@').first ??
                'User',
            email: user.email ?? '',
            avatarUrl: existing?.avatarUrl ??
                user.userMetadata?['avatar_url'] as String?,
            dateOfBirth: _selectedDob,
            gender: _selectedGender,
            createdAt: existing?.createdAt ?? DateTime.now(),
          ),
        );
      }
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Header
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                ).animate().scale(duration: 400.ms),

                const SizedBox(height: 20),

                Center(
                  child: Text(
                    'Complete Your Profile',
                    style: AppTextStyles.headlineLgMobile(context).copyWith(
                      color: AppColors.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 8),

                Center(
                  child: Text(
                    'A few details help us personalise your\nVitaScan experience.',
                    style: AppTextStyles.bodyMd(context).copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate().fadeIn(delay: 150.ms),

                const SizedBox(height: 40),

                // ── Gender ──────────────────────────────────────
                _Label(label: 'Gender'),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  hint: const Text('Select gender'),
                  isExpanded: true,
                  decoration: _inputDecoration(),
                  items: _genders
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedGender = v),
                  validator: (v) => v == null ? 'Please select gender' : null,
                  dropdownColor: Colors.white,
                  style: AppTextStyles.bodyMd(context)
                      .copyWith(color: AppColors.onSurface),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 18),

                // ── Date of Birth ────────────────────────────────
                _Label(label: 'Date of Birth'),
                TextFormField(
                  controller: _dobCtrl,
                  readOnly: true,
                  onTap: _pickDob,
                  decoration: _inputDecoration(
                    hint: 'Select date of birth',
                    suffix: const Icon(
                      Icons.calendar_month_outlined,
                      color: AppColors.outline,
                      size: 20,
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Please select date of birth' : null,
                ).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 18),

                // ── Age (auto-filled but editable) ───────────────
                _Label(label: 'Age'),
                TextFormField(
                  controller: _ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(hint: 'Years'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final n = int.tryParse(v);
                    if (n == null || n < 1 || n > 120) return 'Enter a valid age';
                    return null;
                  },
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 40),

                // ── Save Button ──────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.primary.withOpacity(0.3),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue to VitaScan',
                                style: AppTextStyles.labelMd(context).copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 20),
                            ],
                          ),
                  ),
                ).animate().fadeIn(delay: 350.ms),

                const SizedBox(height: 16),

                // Skip option
                Center(
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.home),
                    child: Text(
                      'Skip for now',
                      style: AppTextStyles.bodyMd(context).copyWith(
                        color: AppColors.onSurfaceVariant,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

class _Label extends StatelessWidget {
  final String label;
  const _Label({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: AppTextStyles.labelMd(context).copyWith(
          color: const Color(0xFF475569),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
