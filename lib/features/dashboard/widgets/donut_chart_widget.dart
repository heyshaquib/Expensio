import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/providers.dart';
import '../../../core/database/app_database.dart';

class DonutChartWidget extends ConsumerWidget {
  const DonutChartWidget({super.key});

  static const _categoryColors = <String, Color>{
    'groceries': Color(0xFF81C784),
    'food': Color(0xFFFF6B6B),
    'fuel': Color(0xFFFFB74D),
    'entertainment': Color(0xFFFF8A65),
    'shopping': Color(0xFFFFE66D),
    'investments': Color(0xFF4DB5E1),
    'internet': Color(0xFF4ECDC4),
    'electricity': Color(0xFFFFD54F),
    'water': Color(0xFF64B5F6),
    'travel': Color(0xFF95E1D3),
    'electronics': Color(0xFFBA68C8),
    'taxes': Color(0xFFE0E0E0),
    'health': Color(0xFF80CBC4),
    'transport': Color(0xFF4DD0E1),
    'leisure': Color(0xFFF4A261),
    'rent': Color(0xFF7986CB),
    'education': Color(0xFF9575CD),
    'insurance': Color(0xFF4DB6AC),
    'other': Color(0xFF90A4AE),
  };

  Color _resolveCategoryColor(String key, ColorScheme colorScheme) {
    if (_categoryColors.containsKey(key)) {
      return _categoryColors[key]!;
    }

    // Deterministic custom category color generation using a simple hash map from beautiful preset colors
    final presetColors = [
      const Color(0xFFE57373),
      const Color(0xFFF06292),
      const Color(0xFFBA68C8),
      const Color(0xFF9575CD),
      const Color(0xFF7986CB),
      const Color(0xFF64B5F6),
      const Color(0xFF4FC3F7),
      const Color(0xFF4DD0E1),
      const Color(0xFF4DB6AC),
      const Color(0xFF81C784),
      const Color(0xFFAED581),
      const Color(0xFFFFD54F),
      const Color(0xFFFFB74D),
      const Color(0xFFFF8A65),
    ];
    final hash = key.hashCode.abs();
    return presetColors[hash % presetColors.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthArg = DateTime(now.year, now.month, 1);
    final expenses = ref.watch(expensesByCategoryProvider(monthArg));
    final categories = ref.watch(categoriesProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return expenses.when(
      data: (expMap) {
        if (expMap.isEmpty) {
          return Container(
            height: 200,
            alignment: Alignment.center,
            child: Text(
              'No spending data this month',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        // Sort by value, take top 5
        final sorted =
            expMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        final top5 = sorted.take(5).toList();
        final total = top5.fold<double>(0, (s, e) => s + e.value);

        return SizedBox(
          height: 220,
          child: Row(
            children: [
              // Donut chart
              Expanded(
                flex: 3,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 40,
                    sections:
                        top5.map((e) {
                          final pct = (e.value / total * 100).toStringAsFixed(
                            0,
                          );
                          return PieChartSectionData(
                            value: e.value,
                            title: '$pct%',
                            titleStyle: textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            color: _resolveCategoryColor(e.key, colorScheme),
                            radius: 32,
                          );
                        }).toList(),
                  ),
                ),
              ),
              // Legend
              Expanded(
                flex: 2,
                child: categories.when(
                  data: (cats) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          top5.map((e) {
                            final cat = cats.firstWhere(
                              (c) => c.id == e.key,
                              orElse:
                                  () => CategoryEntity(
                                    id: e.key,
                                    name: 'Miscellaneous',
                                    emoji: '🧾',
                                    isCustom: false,
                                    sortOrder: 0,
                                  ),
                            );
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: _resolveCategoryColor(
                                        e.key,
                                        colorScheme,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${cat.emoji} ${cat.name}',
                                      style: textTheme.labelSmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        );
      },
      loading:
          () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
      error:
          (e, _) =>
              SizedBox(height: 200, child: Center(child: Text('Error: $e'))),
    );
  }
}
