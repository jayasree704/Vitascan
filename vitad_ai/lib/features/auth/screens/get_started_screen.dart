import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:vitad_ai/core/theme/app_theme.dart';
import 'package:vitad_ai/core/router/app_router.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCE8F6),
      body: Stack(
        children: [
          // Hero Background Image (Stethoscope)
          Positioned.fill(
            child: Image.asset(
              'assets/images/get_started_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // Gradient overlay for smooth readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.0),
                    const Color(0xFFEAF1FA).withOpacity(0.6),
                    const Color(0xFFEAF1FA).withOpacity(0.95),
                    const Color(0xFFEAF1FA),
                  ],
                  stops: const [0.0, 0.4, 0.68, 1.0],
                ),
              ),
            ),
          ),

          // Top App Bar Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: const Icon(Icons.medical_services, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'VitaScan',
                    style: AppTextStyles.headlineMd(context).copyWith(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content Container (Elevated Info Card above Button)
          SafeArea(
            child: Column(
              children: [
                const Spacer(),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Clinical Grade Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'CLINICAL GRADE AI',
                                style: AppTextStyles.labelMd(context).copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),

                        const SizedBox(height: 16),

                        // Main Title
                        Text(
                          'Precision\nVitamin D Analysis',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headlineLgMobile(context).copyWith(
                            color: const Color(0xFF0F172A),
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                        const SizedBox(height: 12),

                        // Subtitle Info
                        Text(
                          'Measure your health with clinical-grade salivary testing and personalized AI insights.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMd(context).copyWith(
                            color: const Color(0xFF475569),
                            height: 1.4,
                          ),
                        ).animate().fadeIn(delay: 300.ms),

                        const SizedBox(height: 18),

                        // Feature Pills
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: const [
                            _FeaturePill(icon: Icons.bolt, label: 'AI Powered'),
                            _FeaturePill(icon: Icons.verified_user, label: 'Clinically Verified'),
                            _FeaturePill(icon: Icons.analytics, label: 'Instant Results'),
                          ],
                        ).animate().fadeIn(delay: 400.ms),

                        const SizedBox(height: 24),

                        // Primary CTA Button: Create Account
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => context.go(AppRoutes.signUp),
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
                                  'Create User Account',
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
                        ).animate().fadeIn(delay: 500.ms),

                        const SizedBox(height: 12),

                        // Secondary Option: Continue Directly / Open Access
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => context.go(AppRoutes.home),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Continue without Account',
                              style: AppTextStyles.labelMd(context).copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 550.ms),

                        const SizedBox(height: 16),

                        // Sign In Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: AppTextStyles.bodyMd(context).copyWith(
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go(AppRoutes.signIn),
                              child: Text(
                                'Sign In',
                                style: AppTextStyles.bodyMd(context).copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 600.ms),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelMd(context).copyWith(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
