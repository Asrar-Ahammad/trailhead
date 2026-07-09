import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trailhead_mobile/features/haptics/application/haptics_service.dart';
import 'dart:math';

class ChartDataPoint {
  final double x; // Distance in km
  final double y; // Metric value (e.g. pace in seconds, elevation in m, cadence in spm)
  
  ChartDataPoint(this.x, this.y);
}

enum MetricType { pace, cadence, elevation }

class RunMetricChart extends ConsumerStatefulWidget {
  final String title;
  final MetricType type;
  final List<ChartDataPoint> data;
  final Color color;
  final double? average;

  const RunMetricChart({
    super.key,
    required this.title,
    required this.type,
    required this.data,
    required this.color,
    this.average,
  });

  @override
  ConsumerState<RunMetricChart> createState() => _RunMetricChartState();
}

class _RunMetricChartState extends ConsumerState<RunMetricChart> {
  int? _lastTouchedIndex;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    
    if (widget.data.isEmpty) {
      return const SizedBox.shrink();
    }

    // Process data to avoid infinite or NaN values
    final cleanData = widget.data.where((p) => p.y.isFinite && !p.y.isNaN).toList();
    if (cleanData.isEmpty) return const SizedBox.shrink();

    // Determine Y-axis bounds
    double minY = cleanData.map((e) => e.y).reduce(min);
    double maxY = cleanData.map((e) => e.y).reduce(max);
    
    if (widget.type == MetricType.pace) {
      // Invert pace so faster (lower seconds) is higher on the chart
      // We will plot negative values
      minY = -maxY;
      maxY = -cleanData.map((e) => e.y).reduce(min);
      
      // Add padding
      final yRange = max(maxY - minY, 1.0);
      minY = minY - yRange * 0.1;
      maxY = maxY + yRange * 0.1;
    } else {
      // Add padding to minY and maxY for visual breathing room
      final yRange = max(maxY - minY, 1.0);
      minY = max(0, minY - yRange * 0.1);
      maxY = maxY + yRange * 0.1;
    }

    final double minX = cleanData.first.x;
    final double maxX = cleanData.last.x;
    
    final List<FlSpot> spots = cleanData.map((p) {
      return FlSpot(p.x, widget.type == MetricType.pace ? -p.y : p.y);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: AppTextStyles.headline(color: colors.textPrimary).copyWith(fontSize: 20),
            ),
            Icon(PhosphorIcons.info(), color: colors.textSecondary, size: 20),
          ],
        ),
        const SizedBox(height: 16),
        // Chart
        Container(
          height: 200,
          padding: const EdgeInsets.only(right: 16, top: 16, bottom: 8, left: 0),
          decoration: BoxDecoration(
            color: colors.surfaceRaised,
            borderRadius: BorderRadius.circular(12),
          ),
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                  if (touchResponse?.lineBarSpots != null && touchResponse!.lineBarSpots!.isNotEmpty) {
                    final touchedIndex = touchResponse.lineBarSpots!.first.spotIndex;
                    if (_lastTouchedIndex != touchedIndex) {
                      _lastTouchedIndex = touchedIndex;
                      ref.read(hapticsServiceProvider).lightImpact();
                    }
                  } else {
                    _lastTouchedIndex = null;
                  }
                },
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) => widget.color.withOpacity(0.8),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      String valStr;
                      if (widget.type == MetricType.pace) {
                        final seconds = (-spot.y).round();
                        final m = seconds ~/ 60;
                        final s = seconds % 60;
                        valStr = '$m:${s.toString().padLeft(2, '0')} /km';
                      } else if (widget.type == MetricType.cadence) {
                        valStr = '${spot.y.round()} spm';
                      } else {
                        valStr = '${spot.y.round()} m';
                      }
                      return LineTooltipItem(
                        valStr,
                        AppTextStyles.labelCaps(color: colors.background),
                      );
                    }).toList();
                  },
                ),
              ),
              minX: minX,
              maxX: maxX,
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: colors.border.withOpacity(0.5),
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: colors.border.withOpacity(0.5),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.max || value == meta.min) return const SizedBox.shrink();
                      
                      String text;
                      if (widget.type == MetricType.pace) {
                        final seconds = (-value).round();
                        final m = seconds ~/ 60;
                        final s = seconds % 60;
                        text = '$m:${s.toString().padLeft(2, '0')}';
                      } else {
                        text = value.round().toString();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          text,
                          style: AppTextStyles.label(color: colors.textSecondary).copyWith(fontSize: 10),
                          textAlign: TextAlign.right,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: max((maxX - minX) / 4, 0.5),
                    getTitlesWidget: (value, meta) {
                      if (value == meta.max || value == meta.min || value == 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '${value.toStringAsFixed(1)} km',
                          style: AppTextStyles.label(color: colors.textSecondary).copyWith(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: widget.color,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: widget.color.withOpacity(0.15),
                  ),
                ),
              ],
              extraLinesData: widget.average != null ? ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: widget.type == MetricType.pace ? -widget.average! : widget.average!,
                    color: colors.textPrimary.withOpacity(0.6),
                    strokeWidth: 1.5,
                    dashArray: [4, 4],
                  ),
                ],
              ) : null,
            ),
          ),
        ),
      ],
    );
  }
}
