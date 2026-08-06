import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vitad_ai/core/theme/app_theme.dart';
import 'package:vitad_ai/core/router/app_router.dart';
import 'package:vitad_ai/core/services/report_service.dart';
import 'package:vitad_ai/domain/models/scan_result.dart';

class AnalysisResultsScreen extends StatefulWidget {
  final ScanResult? result;

  const AnalysisResultsScreen({super.key, this.result});

  @override
  State<AnalysisResultsScreen> createState() => _AnalysisResultsScreenState();
}

class _AnalysisResultsScreenState extends State<AnalysisResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _gaugeController;
  late Animation<double> _gaugeAnimation;

  late final ScanResult _data;
  final ReportService _reportService = ReportService();

  bool _isDownloading = false;
  bool _isSharing = false;

  Color get _statusColor {
    if (_data.vitaminDLevel < 20 || _data.status == 'Deficient') {
      return AppColors.palePink; // Pale Pink for Deficiency
    }
    if (_data.vitaminDLevel < 30 || _data.status == 'Insufficient') {
      return AppColors.lightPink; // Light Pink for Insufficient
    }
    return AppColors.darkPink; // Dark Pink for Sufficient
  }

  List<RecommendedFood> _getDynamicFoodRecommendations(double level, String status) {
    if (level < 20 || status == 'Deficient') {
      return const [
        RecommendedFood(
          name: 'Cod Liver Oil',
          description: 'One of the most concentrated natural sources of Vitamin D3 (450+ IU per tsp).',
          category: 'Supplements',
        ),
        RecommendedFood(
          name: 'Wild-Caught Salmon',
          description: 'Rich in Vitamin D3 (500-1000 IU/serving) and Omega-3 fatty acids.',
          category: 'Seafood',
        ),
        RecommendedFood(
          name: 'UV-Exposed Mushrooms',
          description: 'Synthesizes natural Vitamin D2 to rapidly boost depleted levels.',
          category: 'Vegetables',
        ),
        RecommendedFood(
          name: 'Fortified Milk & OJ',
          description: 'Essential daily fortified beverages for baseline Vitamin D recovery.',
          category: 'Fortified Foods',
        ),
      ];
    } else if (level < 30 || status == 'Insufficient') {
      return const [
        RecommendedFood(
          name: 'Egg Yolks',
          description: 'Contain moderate amounts of Vitamin D3, especially from pasture-raised hens.',
          category: 'Dairy & Eggs',
        ),
        RecommendedFood(
          name: 'Sardines & Tuna',
          description: 'Affordable, accessible seafood sources rich in Vitamin D3.',
          category: 'Seafood',
        ),
        RecommendedFood(
          name: 'Fortified Cereals & Yogurt',
          description: 'Reliable daily fortified options for steady absorption.',
          category: 'Fortified Foods',
        ),
        RecommendedFood(
          name: 'Beef Liver',
          description: 'Provides Vitamin D, iron, and key micronutrients.',
          category: 'Meat',
        ),
      ];
    } else {
      return const [
        RecommendedFood(
          name: 'Avocado & Salmon',
          description: 'Maintains optimal lipid-soluble Vitamin D absorption.',
          category: 'Healthy Fats',
        ),
        RecommendedFood(
          name: 'Fortified Plant Milks',
          description: 'Almond or Soy milk fortified for daily maintenance.',
          category: 'Dairy Alternatives',
        ),
        RecommendedFood(
          name: 'Whole Eggs & Cheese',
          description: 'Provides steady daily dietary Vitamin D support.',
          category: 'Dairy & Eggs',
        ),
        RecommendedFood(
          name: 'Spinach & Mushrooms',
          description: 'Supports calcium and Vitamin D metabolic synergy.',
          category: 'Vegetables',
        ),
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    final initialData = widget.result ??
        ScanResult(
          userId: 'demo',
          patientName: 'Alex Johnson',
          patientAge: 35,
          patientGender: 'Male',
          vitaminDLevel: 12.5,
          status: 'Deficient',
          aiConfidence: 0.96,
          recommendations: const [],
          lifestyleTips: const [
            'Expose arms and legs to direct sunlight for 15-20 minutes daily.',
            'Pair Vitamin D rich foods with healthy fats for optimal absorption.',
            'Retest your levels in 8-12 weeks to monitor progress.'
          ],
          createdAt: DateTime.now(),
        );

    final dynamicFoods = _getDynamicFoodRecommendations(
      initialData.vitaminDLevel,
      initialData.status,
    );

    _data = ScanResult(
      id: initialData.id,
      userId: initialData.userId,
      patientName: initialData.patientName,
      patientAge: initialData.patientAge,
      patientGender: initialData.patientGender,
      imageUrl: initialData.imageUrl,
      vitaminDLevel: initialData.vitaminDLevel,
      status: initialData.status,
      aiConfidence: initialData.aiConfidence,
      aiRawResponse: initialData.aiRawResponse,
      recommendations: initialData.recommendations.isNotEmpty
          ? initialData.recommendations
          : dynamicFoods,
      lifestyleTips: initialData.lifestyleTips,
      createdAt: initialData.createdAt,
    );

    _gaugeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _gaugeAnimation = Tween<double>(
            begin: 0, end: (_data.vitaminDLevel / 100).clamp(0.0, 1.0))
        .animate(
      CurvedAnimation(parent: _gaugeController, curve: Curves.easeOutCubic),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _gaugeController.forward();
    });
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    super.dispose();
  }

  Future<void> _handleDownload() async {
    setState(() => _isDownloading = true);
    try {
      final file = await _reportService.downloadReport(_data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report downloaded to: ${file.path}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download report: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _handleShare() async {
    setState(() => _isSharing = true);
    try {
      await _reportService.shareReport(_data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share report: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Analysis Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _StatusOverviewCard(
              data: _data,
              statusColor: _statusColor,
              gaugeAnimation: _gaugeAnimation,
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),

            const SizedBox(height: 24),

            _RecommendationsSection(foods: _data.recommendations)
                .animate()
                .fadeIn(delay: 300.ms),

            const SizedBox(height: 24),

            _LifestyleTips(tips: _data.lifestyleTips)
                .animate()
                .fadeIn(delay: 400.ms),

            const SizedBox(height: 24),

            // Report Actions Card (Download & Share)
            _ReportActionsCard(
              isDownloading: _isDownloading,
              isSharing: _isSharing,
              onDownload: _handleDownload,
              onShare: _handleShare,
            ).animate().fadeIn(delay: 450.ms),

            const SizedBox(height: 32),

            // Navigation Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.history),
                    icon: const Icon(Icons.history, color: AppColors.primary),
                    label: const Text('View History'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go(AppRoutes.scan),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('New Scan'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StatusOverviewCard extends StatelessWidget {
  final ScanResult data;
  final Color statusColor;
  final Animation<double> gaugeAnimation;

  const _StatusOverviewCard({
    required this.data,
    required this.statusColor,
    required this.gaugeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border(left: BorderSide(color: statusColor, width: 6)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: gaugeAnimation,
                builder: (ctx, child) {
                  return SizedBox(
                    width: 110,
                    height: 110,
                    child: CustomPaint(
                      painter: _GaugePainter(
                          value: gaugeAnimation.value, color: statusColor),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              data.vitaminDLevel.toStringAsFixed(1),
                              style: AppTextStyles.dataValue(context)
                                  .copyWith(color: AppColors.onSurface, fontSize: 24),
                            ),
                            Text('ng/mL',
                                style: AppTextStyles.bodyMd(context).copyWith(
                                    fontSize: 11, color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        data.status,
                        style: AppTextStyles.labelMd(context).copyWith(
                          color: statusColor == AppColors.palePink
                              ? const Color(0xFF881337)
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      data.status == 'Sufficient'
                          ? 'Your Vitamin D levels are within the optimal clinical range of 30-100 ng/mL.'
                          : 'Your Vitamin D levels are below the optimal clinical range of 30-100 ng/mL.',
                      style: AppTextStyles.bodyMd(context).copyWith(
                          color: AppColors.onSurfaceVariant, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    _LegendRow(color: AppColors.deficient, label: 'Deficient < 20'),
                    const SizedBox(height: 4),
                    _LegendRow(color: AppColors.insufficient, label: 'Insufficient 20-30'),
                    const SizedBox(height: 4),
                    _LegendRow(color: AppColors.sufficient, label: 'Sufficient 30-100'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.outlineVariant),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: statusColor),
              const SizedBox(width: 4),
              Text(
                'Test Date: ${DateFormat('MMM d, yyyy').format(data.createdAt)}',
                style: AppTextStyles.labelMd(context).copyWith(
                    color: AppColors.onSurfaceVariant, fontSize: 11),
              ),
              if (data.patientName != null && data.patientName!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          data.patientName!,
                          style: AppTextStyles.labelMd(context).copyWith(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: AppTextStyles.labelMd(context)
                .copyWith(fontSize: 10, color: AppColors.onSurfaceVariant)),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  _GaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final trackPaint = Paint()
      ..color = AppColors.surfaceContainerHighest
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    const startAngle = -2.356;
    const sweepFull = 4.712;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
        sweepFull, false, trackPaint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
        sweepFull * value, false, progressPaint);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.value != value;
}

class _RecommendationsSection extends StatelessWidget {
  final List<RecommendedFood> foods;
  const _RecommendationsSection({required this.foods});

  @override
  Widget build(BuildContext context) {
    if (foods.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Personalized Food Suggestions',
                style: AppTextStyles.headlineMd(context)),
            const Icon(Icons.restaurant_menu, color: AppColors.primary, size: 20),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.82, // Fixes bottom overflowed by 15 pixels
          ),
          itemCount: foods.length,
          itemBuilder: (context, i) {
            final food = foods[i];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.restaurant_outlined,
                        color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    food.name,
                    style: AppTextStyles.labelMd(context).copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      food.description,
                      style: AppTextStyles.bodyMd(context).copyWith(
                          color: AppColors.onSurfaceVariant, fontSize: 11, height: 1.3),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LifestyleTips extends StatelessWidget {
  final List<String> tips;
  const _LifestyleTips({required this.tips});

  @override
  Widget build(BuildContext context) {
    if (tips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lifestyle Improvements', style: AppTextStyles.headlineMd(context)),
        const SizedBox(height: 12),
        ...tips.map(
          (tip) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.check_circle_outline,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      tip,
                      style: AppTextStyles.bodyMd(context).copyWith(
                          color: AppColors.onSurfaceVariant, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportActionsCard extends StatelessWidget {
  final bool isDownloading;
  final bool isSharing;
  final VoidCallback onDownload;
  final VoidCallback onShare;

  const _ReportActionsCard({
    required this.isDownloading,
    required this.isSharing,
    required this.onDownload,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.picture_as_pdf,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export Clinical Report',
                      style: AppTextStyles.labelMd(context).copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Download or share a PDF summary of your scan results',
                      style: AppTextStyles.bodyMd(context).copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isDownloading ? null : onDownload,
                  icon: isDownloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.download_rounded, size: 18),
                  label: Text(isDownloading ? 'Saving...' : 'Download PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isSharing ? null : onShare,
                  icon: isSharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.share_outlined, size: 18),
                  label: Text(isSharing ? 'Preparing...' : 'Share Report'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

