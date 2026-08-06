import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:vitad_ai/core/theme/app_theme.dart';
import 'package:vitad_ai/core/router/app_router.dart';
import 'package:vitad_ai/features/auth/providers/auth_provider.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  String _getUserDisplayName(WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return 'Alex';
    
    final fullName = (user.userMetadata?['full_name'] as String?) ??
                     (user.userMetadata?['name'] as String?);
    if (fullName != null && fullName.trim().isNotEmpty) {
      return fullName.trim().split(' ').first;
    }
    
    if (user.email != null && user.email!.contains('@')) {
      final emailPrefix = user.email!.split('@').first;
      if (emailPrefix.isNotEmpty) {
        return emailPrefix[0].toUpperCase() + emailPrefix.substring(1);
      }
    }
    
    return 'User';
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source, imageQuality: 90);
      if (image != null && context.mounted) {
        context.go(AppRoutes.patientDetails, extra: File(image.path));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image selection error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = _getUserDisplayName(ref);
    final formattedDate = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.surface,
              elevation: 0,
              title: Row(
                children: [
                  const Icon(Icons.medical_services, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'VitaScan',
                    style: AppTextStyles.headlineMd(context).copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              actions: null, // Top right profile logo removed per user request
            ),

            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Greeting (Dynamic user name)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $userName 👋',
                        style: AppTextStyles.headlineLgMobile(context),
                      ),
                      Text(
                        formattedDate,
                        style: AppTextStyles.bodyMd(context).copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ).animate().fadeIn().slideX(begin: -0.1),

                  const SizedBox(height: 24),

                  // Status Card
                  _StatusCard(context: context).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),

                  const SizedBox(height: 24),

                  // Scan Actions
                  Text(
                    'Analyze Test Strip',
                    style: AppTextStyles.headlineMd(context),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.photo_camera,
                          label: 'Take Photo',
                          color: const Color(0xFFFFB6C1),
                          textColor: AppColors.onSurface,
                          onTap: () => _pickImage(context, ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.upload_file,
                          label: 'Upload Image',
                          color: AppColors.surface,
                          textColor: AppColors.primary,
                          bordered: true,
                          onTap: () => _pickImage(context, ImageSource.gallery),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 32),

                  // Quick Stats
                  _QuickStats().animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 24),

                  // Instructions Section
                  _HowToScan(context: context).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 24),

                  // Recent Result
                  _RecentResultCard().animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status Card ──────────────────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  final BuildContext context;
  const _StatusCard({required this.context});

  @override
  Widget build(BuildContext _) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT STATUS',
                    style: AppTextStyles.labelMd(context).copyWith(color: AppColors.onSurfaceVariant, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sufficient',
                    style: AppTextStyles.headlineLg(context).copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('42', style: AppTextStyles.headlineLg(context)),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'ng/mL',
                          style: AppTextStyles.bodyMd(context).copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Last tested: Oct 24',
                    style: AppTextStyles.labelMd(context).copyWith(color: AppColors.outline, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress Bar
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: [
                      Expanded(flex: 33, child: Container(color: AppColors.deficient)),
                      Expanded(flex: 33, child: Container(color: AppColors.insufficient)),
                      Expanded(flex: 34, child: Container(color: AppColors.sufficient)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Deficient', style: AppTextStyles.labelMd(context).copyWith(fontSize: 10, color: AppColors.onSurfaceVariant)),
                  Text('Insufficient', style: AppTextStyles.labelMd(context).copyWith(fontSize: 10, color: AppColors.onSurfaceVariant)),
                  Text('Sufficient', style: AppTextStyles.labelMd(context).copyWith(fontSize: 10, color: AppColors.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final bool bordered;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
    this.bordered = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: bordered
              ? BoxDecoration(
                  border: Border.all(color: AppColors.outlineVariant),
                  borderRadius: BorderRadius.circular(16),
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.35),
                ),
                child: Icon(icon, color: textColor, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelMd(context).copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick Stats ────────────────────────────────────────────────────────
class _QuickStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatItem(value: '12', label: 'Total Tests', icon: Icons.science_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _StatItem(value: '94%', label: 'AI Accuracy', icon: Icons.psychology_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _StatItem(value: '3mo', label: 'Tracking', icon: Icons.timeline_outlined)),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StatItem({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.headlineMd(context).copyWith(color: AppColors.onSurface)),
          Text(label, style: AppTextStyles.labelMd(context).copyWith(fontSize: 10, color: AppColors.onSurfaceVariant), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── How to Scan ────────────────────────────────────────────────────────
class _HowToScan extends StatelessWidget {
  final BuildContext context;
  const _HowToScan({required this.context});

  @override
  Widget build(BuildContext _) {
    final steps = [
      ('Step 1', 'Capture complete strip clearly in frame'),
      ('Step 2', 'Ensure good lighting with no shadows'),
      ('Step 3', 'Wait for AI analysis to complete'),
      ('Step 4', 'Review your personalized results'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOW TO SCAN',
          style: AppTextStyles.labelMd(context).copyWith(color: AppColors.primary, letterSpacing: 1.4),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            children: steps.asMap().entries.map((e) {
              final isLast = e.key == steps.length - 1;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.outlineVariant, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Text(e.value.$1, style: AppTextStyles.labelMd(context).copyWith(color: AppColors.primary)),
                    const SizedBox(width: 16),
                    Expanded(child: Text(e.value.$2, style: AppTextStyles.bodyMd(context))),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Recent Result Card ─────────────────────────────────────────────────
class _RecentResultCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(AppRoutes.history),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary.withOpacity(0.08), AppColors.primaryFixed],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.bar_chart, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('View Full History', style: AppTextStyles.headlineMd(context).copyWith(fontSize: 16)),
                  Text(
                    '12 tests recorded · Last 90 days',
                    style: AppTextStyles.bodyMd(context).copyWith(color: AppColors.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
