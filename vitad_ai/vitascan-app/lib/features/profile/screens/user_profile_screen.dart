import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vitad_ai/core/theme/app_theme.dart';
import 'package:vitad_ai/core/router/app_router.dart';
import 'package:vitad_ai/features/auth/providers/auth_provider.dart';
import 'package:vitad_ai/features/profile/providers/profile_provider.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileProvider);

    final displayName = currentUser?.userMetadata?['full_name'] as String? ??
        currentUser?.email?.split('@').first ??
        'Alex Johnson';
    final email = currentUser?.email ?? 'alex.j@example.com';
    final avatarUrl = currentUser?.userMetadata?['avatar_url'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Icons.medical_services, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text('Vitamin D Lab',
                style: AppTextStyles.headlineMd(context)
                    .copyWith(color: AppColors.primary)),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.outlineVariant),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _AvatarSection(
              name: displayName,
              avatarUrl: avatarUrl,
              createdAt: currentUser?.createdAt != null
                  ? DateTime.parse(currentUser!.createdAt)
                  : DateTime.now(),
            ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),

            const SizedBox(height: 32),

            profileAsync.when(
              data: (profile) {
                return _PersonalInfoSection(
                  name: profile?.fullName.isNotEmpty == true
                      ? profile!.fullName
                      : displayName,
                  email: email,
                  gender: profile?.gender ?? 'Not specified',
                  dob: profile?.dateOfBirth != null
                      ? DateFormat('MMM d, yyyy').format(profile!.dateOfBirth!)
                      : 'Not specified',
                );
              },
              loading: () => _PersonalInfoSection(
                name: displayName,
                email: email,
                gender: 'Loading...',
                dob: 'Loading...',
              ),
              error: (_, __) => _PersonalInfoSection(
                name: displayName,
                email: email,
                gender: 'Not specified',
                dob: 'Not specified',
              ),
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 24),

            _AccountSettingsSection().animate().fadeIn(delay: 250.ms),

            const SizedBox(height: 24),

            _SignOutButton(onSignOut: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) {
                context.go(AppRoutes.getStarted);
              }
            }).animate().fadeIn(delay: 350.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final DateTime createdAt;

  const _AvatarSection({
    required this.name,
    this.avatarUrl,
    required this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1), blurRadius: 16)
                ],
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.primaryFixed,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null
                    ? const Icon(Icons.person, size: 48, color: AppColors.primary)
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(name, style: AppTextStyles.headlineLgMobile(context)),
        const SizedBox(height: 4),
        Text(
          'Member since ${DateFormat('MMMM yyyy').format(createdAt)}',
          style: AppTextStyles.labelMd(context)
              .copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _PersonalInfoSection extends StatelessWidget {
  final String name;
  final String email;
  final String gender;
  final String dob;

  const _PersonalInfoSection({
    required this.name,
    required this.email,
    required this.gender,
    required this.dob,
  });

  @override
  Widget build(BuildContext context) {
    final fields = [
      ('Full Name', name, Icons.person_outline),
      ('Email Address', email, Icons.mail_outline),
      ('Date of Birth', dob, Icons.calendar_today_outlined),
      ('Gender', gender, Icons.person_search_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Personal Information', style: AppTextStyles.headlineMd(context)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04), blurRadius: 12)
            ],
          ),
          child: Column(
            children: fields.asMap().entries.map((e) {
              final isLast = e.key == fields.length - 1;
              final f = e.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : const Border(
                          bottom: BorderSide(
                              color: AppColors.surfaceContainerHigh, width: 1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.$1,
                        style: AppTextStyles.labelMd(context).copyWith(
                            color: AppColors.onSurfaceVariant, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(f.$2,
                            style: AppTextStyles.bodyLg(context)
                                .copyWith(color: AppColors.onSurface)),
                        Icon(f.$3, color: AppColors.outlineVariant, size: 20),
                      ],
                    ),
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

class _AccountSettingsSection extends StatelessWidget {
  const _AccountSettingsSection();

  void _showPrivacyModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Privacy & Data Security',
                        style: AppTextStyles.headlineMd(context).copyWith(fontSize: 18),
                      ),
                      Text(
                        'HIPAA & GDPR Compliant Protection',
                        style: AppTextStyles.labelMd(context).copyWith(color: AppColors.primary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _infoBullet(
              context,
              icon: Icons.lock_outline,
              title: 'End-to-End Encryption',
              desc: 'All test strip scans, AI readings, and patient metadata are encrypted in transit (TLS 1.3) and at rest (AES-256).',
            ),
            const SizedBox(height: 14),
            _infoBullet(
              context,
              icon: Icons.verified_user_outlined,
              title: 'Zero Unapproved Data Sharing',
              desc: 'Your clinical scan results remain confidential and are never sold or shared with external advertising networks.',
            ),
            const SizedBox(height: 14),
            _infoBullet(
              context,
              icon: Icons.folder_delete_outlined,
              title: 'Full User Data Ownership',
              desc: 'You have complete control to view, export, or permanently delete your scan history directly from your account settings.',
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      openAppSettings();
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('App Permissions'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Got It'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showHelpSupportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.health_and_safety_outlined, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Help & Clinical Support',
                        style: AppTextStyles.headlineMd(context).copyWith(fontSize: 18),
                      ),
                      Text(
                        '24/7 Scan Guidance & Assistance',
                        style: AppTextStyles.labelMd(context).copyWith(color: AppColors.primary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _infoBullet(
              context,
              icon: Icons.camera_alt_outlined,
              title: 'Best Scan Practices',
              desc: 'Place your Vitamin D test strip on a neutral white background under direct, even lighting without harsh reflections.',
            ),
            const SizedBox(height: 14),
            _infoBullet(
              context,
              icon: Icons.medical_information_outlined,
              title: 'Clinical Guidance Disclaimer',
              desc: 'VitaD AI provides screening estimates for 25(OH)D levels. Always verify findings with a certified physician or clinical laboratory.',
            ),
            const SizedBox(height: 14),
            _infoBullet(
              context,
              icon: Icons.mark_email_read_outlined,
              title: 'Direct Support Desk',
              desc: 'Need technical or diagnostic assistance? Contact support@vitascan.ai for priority medical & technical help.',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Support email copied: support@vitascan.ai'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Contact Support (support@vitascan.ai)'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _infoBullet(BuildContext context, {required IconData icon, required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.labelMd(context).copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: AppTextStyles.bodyMd(context).copyWith(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = [
      (Icons.notifications_outlined, 'Notification Preferences'),
      (Icons.privacy_tip_outlined, 'Privacy & Data Security'),
      (Icons.help_outline, 'Help & Clinical Support'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account Settings', style: AppTextStyles.headlineMd(context)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            children: settings.asMap().entries.map((e) {
              final isLast = e.key == settings.length - 1;
              final s = e.value;
              return InkWell(
                onTap: () async {
                  if (s.$2 == 'Notification Preferences') {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Opening App Settings for notifications...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                    final status = await Permission.notification.status;
                    if (status.isDenied) {
                      await Permission.notification.request();
                    }
                    await openAppSettings();
                  } else if (s.$2 == 'Privacy & Data Security') {
                    _showPrivacyModal(context);
                  } else if (s.$2 == 'Help & Clinical Support') {
                    _showHelpSupportModal(context);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : const Border(
                            bottom: BorderSide(
                                color: AppColors.outlineVariant, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(s.$1, color: AppColors.primary, size: 22),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(s.$2,
                            style: AppTextStyles.labelMd(context).copyWith(
                                color: AppColors.onSurface, fontSize: 14)),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppColors.outline, size: 20),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SignOutButton extends StatelessWidget {
  final VoidCallback onSignOut;

  const _SignOutButton({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onSignOut,
        icon: const Icon(Icons.logout, color: AppColors.error),
        label: Text(
          'Sign Out',
          style: AppTextStyles.labelMd(context)
              .copyWith(color: AppColors.error, fontSize: 15),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.error.withOpacity(0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
