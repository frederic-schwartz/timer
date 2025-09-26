import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../controllers/statistics_controller.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late final StatisticsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = StatisticsController();
    _controller.addListener(_onControllerChanged);
    _controller.initialize();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  double _getMaxValue() {
    // Utiliser les statistiques temporelles si disponibles, sinon les catégories
    if (_controller.timePeriodStats.isNotEmpty) {
      double maxValue = 0.0;
      for (final stat in _controller.timePeriodStats) {
        final activeHours = stat.totalDuration.inMinutes / 60.0;
        final pauseHours = stat.totalPauseDuration.inMinutes / 60.0;
        final maxForPeriod = activeHours > pauseHours ? activeHours : pauseHours;
        if (maxForPeriod > maxValue) {
          maxValue = maxForPeriod;
        }
      }
      return maxValue * 1.1;
    }

    if (_controller.categoryStats.isEmpty) return 1.0;

    double maxValue = 0.0;
    for (final stat in _controller.categoryStats) {
      final activeHours = stat.totalDuration.inMinutes / 60.0;
      final pauseHours = stat.totalPauseDuration.inMinutes / 60.0;
      final maxForCategory = activeHours > pauseHours ? activeHours : pauseHours;
      if (maxForCategory > maxValue) {
        maxValue = maxForCategory;
      }
    }

    // Ajouter une marge de 10% au maximum
    return maxValue * 1.1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = LinearGradient(
      colors: [
        theme.colorScheme.primary.withValues(alpha: 0.9),
        theme.colorScheme.primaryContainer.withValues(alpha: 0.85),
        theme.colorScheme.surface,
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPeriodSelector(theme),
                      const SizedBox(height: 20),
                      _buildChart(theme),
                      const SizedBox(height: 20),
                      _buildCategoryList(theme),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Période',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: [
                  // Première ligne : Jour et Semaine
                  Row(
                    children: [
                      Expanded(
                        child: _buildPeriodButton(theme, TimePeriod.daily, 'Jour'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPeriodButton(theme, TimePeriod.weekly, 'Semaine'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Deuxième ligne : Mois et Année
                  Row(
                    children: [
                      Expanded(
                        child: _buildPeriodButton(theme, TimePeriod.monthly, 'Mois'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPeriodButton(theme, TimePeriod.yearly, 'Année'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_controller.canGoToPreviousPeriod())
                    IconButton(
                      onPressed: _controller.goToPreviousPeriod,
                      icon: const Icon(Icons.chevron_left),
                      iconSize: 28,
                    )
                  else
                    const SizedBox(width: 48),
                  Container(
                    constraints: const BoxConstraints(minWidth: 120),
                    child: Text(
                      _controller.getPeriodLabel(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (_controller.canGoToNextPeriod())
                    IconButton(
                      onPressed: _controller.goToNextPeriod,
                      icon: const Icon(Icons.chevron_right),
                      iconSize: 28,
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodButton(ThemeData theme, TimePeriod period, String label) {
    final isSelected = _controller.selectedPeriod == period;

    return SizedBox(
      height: 48, // Hauteur fixe pour tous les boutons
      child: FilterChip(
        label: SizedBox(
          width: double.infinity,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
        selected: isSelected,
        onSelected: (_) => _controller.setPeriod(period),
        selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
        checkmarkColor: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surface,
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildChart(ThemeData theme) {
    // Prioriser les statistiques temporelles si disponibles
    final useTimePeriodStats = _controller.timePeriodStats.isNotEmpty;
    final hasData = useTimePeriodStats || _controller.categoryStats.isNotEmpty;

    if (!hasData) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.bar_chart_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune donnée pour ${_controller.getPeriodLabel().toLowerCase()}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return useTimePeriodStats ? _buildTimePeriodChart(theme) : _buildCategoryChart(theme);
  }

  Widget _buildTimePeriodChart(ThemeData theme) {
    final timePeriodStats = _controller.timePeriodStats;
    String chartTitle;

    switch (_controller.selectedPeriod) {
      case TimePeriod.weekly:
        chartTitle = 'Répartition par jour de la semaine';
        break;
      case TimePeriod.monthly:
        chartTitle = 'Répartition par jour du mois';
        break;
      case TimePeriod.yearly:
        chartTitle = 'Répartition par mois';
        break;
      default:
        chartTitle = 'Répartition';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              chartTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  maxY: _getMaxValue(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        if (groupIndex >= timePeriodStats.length) return null;

                        final stat = timePeriodStats[groupIndex];
                        final isActiveTime = rodIndex == 0;
                        final duration = isActiveTime ? stat.totalDuration : stat.totalPauseDuration;
                        return BarTooltipItem(
                          '${stat.label}\n${isActiveTime ? 'Temps actif' : 'Temps de pause'}: ${_formatDuration(duration)}\n${stat.sessionCount} session${stat.sessionCount > 1 ? 's' : ''}',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < timePeriodStats.length) {
                            // Pour les statistiques mensuelles, n'afficher qu'un jour sur 2
                            if (_controller.selectedPeriod == TimePeriod.monthly) {
                              final dayNumber = int.tryParse(timePeriodStats[index].label) ?? 0;
                              if (dayNumber % 2 == 0) {
                                return Text(''); // Ne pas afficher les jours pairs
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                timePeriodStats[index].label,
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return Text('');
                        },
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}h',
                            style: theme.textTheme.bodySmall,
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: timePeriodStats.asMap().entries.map((entry) {
                    final index = entry.key;
                    final stat = entry.value;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: stat.totalDuration.inMinutes / 60.0, // Convertir en heures
                          color: theme.colorScheme.primary,
                          width: _getBarWidth(),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: stat.totalPauseDuration.inMinutes / 60.0, // Convertir en heures
                          color: theme.colorScheme.primary.withValues(alpha: 0.4),
                          width: _getBarWidth(),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(theme),
          ],
        ),
      ),
    );
  }

  double _getBarWidth() {
    // Ajuster la largeur des barres selon le nombre d'éléments
    switch (_controller.selectedPeriod) {
      case TimePeriod.weekly:
        return 16.0; // Réduire pour éviter le chevauchement
      case TimePeriod.monthly:
        return 4.0; // Très fin pour les 30+ jours
      case TimePeriod.yearly:
        return 10.0; // Encore plus fin pour éviter le chevauchement
      default:
        return 16.0;
    }
  }

  Widget _buildCategoryChart(ThemeData theme) {
    final categoryStats = _controller.categoryStats;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Répartition par catégorie',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxValue(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final stat = categoryStats[group.x.toInt()];
                        final categoryName = stat.category?.name ?? 'Sans catégorie';
                        final isActiveTime = rodIndex == 0;
                        final duration = isActiveTime ? stat.totalDuration : stat.totalPauseDuration;
                        return BarTooltipItem(
                          '$categoryName\n${isActiveTime ? 'Temps actif' : 'Temps de pause'}: ${_formatDuration(duration)}',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < categoryStats.length) {
                            final stat = categoryStats[index];
                            final categoryName = stat.category?.name ?? 'Sans catégorie';
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                categoryName.length > 8 ? '${categoryName.substring(0, 8)}...' : categoryName,
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return Text('');
                        },
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}h',
                            style: theme.textTheme.bodySmall,
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: categoryStats.asMap().entries.map((entry) {
                    final index = entry.key;
                    final stat = entry.value;

                    Color categoryColor;
                    if (stat.category != null) {
                      categoryColor = Color(int.parse(stat.category!.color.substring(1), radix: 16) + 0xFF000000);
                    } else {
                      categoryColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
                    }

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: stat.totalDuration.inMinutes / 60.0, // Convertir en heures
                          color: categoryColor,
                          width: 16,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: stat.totalPauseDuration.inMinutes / 60.0, // Convertir en heures
                          color: categoryColor.withValues(alpha: 0.4),
                          width: 16,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(ThemeData theme) {
    final categoryStats = _controller.categoryStats;

    if (categoryStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détails par catégorie',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...categoryStats.map((stat) {
              final categoryName = stat.category?.name ?? 'Sans catégorie';
              Color categoryColor;
              if (stat.category != null) {
                categoryColor = Color(int.parse(stat.category!.color.substring(1), radix: 16) + 0xFF000000);
              } else {
                categoryColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: categoryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            categoryName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${stat.sessionCount} session${stat.sessionCount > 1 ? 's' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              color: theme.colorScheme.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(stat.totalDuration),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.pause_circle_outlined,
                              color: theme.colorScheme.secondary,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(stat.totalPauseDuration),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Temps actif',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(width: 24),
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Temps de pause',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}