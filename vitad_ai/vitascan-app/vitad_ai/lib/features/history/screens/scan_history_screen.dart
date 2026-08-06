import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vitad_ai/core/theme/app_theme.dart';
import 'package:vitad_ai/core/router/app_router.dart';
import 'package:vitad_ai/domain/models/scan_result.dart';
import 'package:vitad_ai/features/history/providers/history_provider.dart';

class ScanHistoryScreen extends ConsumerStatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  ConsumerState<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends ConsumerState<ScanHistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(scanHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Scan History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(scanHistoryProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: historyAsync.when(
        data: (history) {
          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.science_outlined,
                      size: 64, color: AppColors.outline),
                  const SizedBox(height: 16),
                  Text(
                    'No Scan Records Found',
                    style: AppTextStyles.headlineMd(context),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Perform your first Vitamin D test scan to track history.',
                    style: AppTextStyles.bodyMd(context)
                        .copyWith(color: AppColors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.go(AppRoutes.scan),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Start New Scan'),
                  ),
                ],
              ),
            );
          }

          final filteredHistory = history.where((item) {
            if (_searchQuery.isEmpty) return true;
            final query = _searchQuery.toLowerCase();
            final nameMatch = item.patientName?.toLowerCase().contains(query) ?? false;
            final statusMatch = item.status.toLowerCase().contains(query);
            return nameMatch || statusMatch;
          }).toList();

          final latestLevel = history.first.vitaminDLevel.toStringAsFixed(1);

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search patient by name...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.outline),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    filled: true,
                    fillColor: AppColors.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.outlineVariant),
                    ),
                  ),
                ),
              ),

              _SummaryRow(
                totalCount: history.length,
                latestLevel: latestLevel,
              ).animate().fadeIn(),

              _TrendChart(history: history).animate().fadeIn(delay: 100.ms),

              Expanded(
                child: filteredHistory.isEmpty
                    ? Center(
                        child: Text(
                          'No patient found matching "$_searchQuery"',
                          style: AppTextStyles.bodyMd(context)
                              .copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        itemCount: filteredHistory.length,
                        itemBuilder: (ctx, i) {
                          return _HistoryCard(record: filteredHistory[i], index: i)
                              .animate()
                              .fadeIn(delay: (100 + i * 40).ms)
                              .slideX(begin: 0.05);
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Failed to load scan history',
                  style: AppTextStyles.headlineMd(context)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(scanHistoryProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final int totalCount;
  final String latestLevel;

  const _SummaryRow({required this.totalCount, required this.latestLevel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              value: '$totalCount',
              label: 'Total Scans',
              icon: Icons.science_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryCard(
              value: latestLevel,
              label: 'Latest (ng/mL)',
              icon: Icons.water_drop_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _SummaryCard(
      {required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: AppTextStyles.headlineMd(context)
                  .copyWith(color: AppColors.onSurface, fontSize: 18)),
          Text(label,
              style: AppTextStyles.labelMd(context)
                  .copyWith(fontSize: 9, color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<ScanResult> history;
  const _TrendChart({required this.history});

  Color _barColor(double level) {
    if (level < 20) return AppColors.deficient;
    if (level < 30) return AppColors.insufficient;
    return AppColors.sufficient;
  }

  @override
  Widget build(BuildContext context) {
    const maxLevel = 50.0;
    // Show latest 10 items oldest→newest
    final displayHistory = history.reversed.take(10).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Container(
        height: 110,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VITAMIN D TREND',
              style: AppTextStyles.labelMd(context).copyWith(
                color: AppColors.primary,
                fontSize: 10,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxBarHeight = constraints.maxHeight;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: displayHistory.map((r) {
                      final barH = ((r.vitaminDLevel / maxLevel).clamp(0.0, 1.0) * maxBarHeight);
                      final color = _barColor(r.vitaminDLevel);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOut,
                                height: barH.clamp(4.0, maxBarHeight),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ScanResult record;
  final int index;
  const _HistoryCard({required this.record, required this.index});

  Color get statusColor {
    if (record.vitaminDLevel < 20) return AppColors.deficient;
    if (record.vitaminDLevel < 30) return AppColors.insufficient;
    return AppColors.sufficient;
  }

  @override
  Widget build(BuildContext context) {
    final patientName = record.patientName ?? 'Patient';
    final ageStr = record.patientAge != null ? '${record.patientAge} yrs' : '';
    final genderStr = record.patientGender ?? '';
    final metaStr = [ageStr, genderStr].where((s) => s.isNotEmpty).join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => context.go(AppRoutes.analysisResults, extra: record),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: statusColor, width: 5),
              right: const BorderSide(color: AppColors.outlineVariant),
              top: const BorderSide(color: AppColors.outlineVariant),
              bottom: const BorderSide(color: AppColors.outlineVariant),
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        record.vitaminDLevel.toStringAsFixed(1),
                        style: AppTextStyles.headlineMd(context).copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text('ng/mL',
                          style: AppTextStyles.labelMd(context)
                              .copyWith(fontSize: 8, color: AppColors.outline)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              patientName,
                              style: AppTextStyles.labelMd(context).copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              record.status,
                              style: AppTextStyles.labelMd(context).copyWith(
                                  color: statusColor, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      if (metaStr.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          metaStr,
                          style: AppTextStyles.labelMd(context).copyWith(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${DateFormat('MMM d, yyyy').format(record.createdAt)} at ${DateFormat('h:mm a').format(record.createdAt)}',
                        style: AppTextStyles.labelMd(context)
                            .copyWith(color: AppColors.outline, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.outlineVariant, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
