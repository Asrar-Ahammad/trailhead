import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:trailhead_mobile/shared/theme/app_colors.dart';
import 'package:trailhead_mobile/shared/theme/app_text_styles.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeDistanceChart extends StatefulWidget {
  final List<double> chartData;
  final AppColors colors;
  final bool useMiles;

  const HomeDistanceChart({
    required this.chartData,
    required this.colors,
    required this.useMiles,
  });

  @override
  State<HomeDistanceChart> createState() => HomeDistanceChartState();
}

class HomeDistanceChartState extends State<HomeDistanceChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final useMiles = widget.useMiles;
    final unitStr = useMiles ? 'MI' : 'KM';
    final double conversion = useMiles ? 0.621371 : 1.0;

    final convertedData = widget.chartData.map((d) => d * conversion).toList();
    final double maxVal = convertedData.fold<double>(
      0.0,
      (prev, val) => val > prev ? val : prev,
    );
    final double maxY = maxVal > 6.0 ? (maxVal * 1.25) : 8.0;

    final todayWeekday = DateTime.now().weekday - 1; // 0 = Mon, 6 = Sun
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    const shortDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  'TRAIL // DAILY MILEAGE',
                  style: GoogleFonts.pixelifySans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: colors.accent,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _touchedIndex != null
                      ? colors.accent.withValues(alpha: 0.15)
                      : colors.surfaceRaised,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _touchedIndex != null
                      ? '${weekdays[_touchedIndex!]}: ${convertedData[_touchedIndex!].toStringAsFixed(1)} $unitStr'
                      : (maxVal > 0
                            ? 'PEAK: ${maxVal.toStringAsFixed(1)} $unitStr'
                            : 'NO RUNS THIS WEEK'),
                  style: AppTextStyles.labelCaps(
                    color: _touchedIndex != null
                        ? colors.accent
                        : colors.textSecondary,
                  ).copyWith(fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bar Chart Container
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => colors.surfaceRaised,
                    tooltipMargin: 6,
                    fitInsideHorizontally: true,
                    fitInsideVertically: false,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    tooltipBorder: BorderSide(
                      color: colors.border.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final val = rod.toY;
                      return BarTooltipItem(
                        '${weekdays[group.x]}\n',
                        AppTextStyles.labelCaps(
                          color: colors.textSecondary,
                        ).copyWith(fontSize: 10),
                        children: [
                          TextSpan(
                            text: '${val.toStringAsFixed(1)} $unitStr',
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    if (event is FlTapDownEvent || event is FlPanDownEvent) {
                      if (response != null && response.spot != null) {
                        setState(() {
                          _touchedIndex = response.spot!.touchedBarGroupIndex;
                        });
                      }
                    } else if (event is FlTapUpEvent ||
                        event is FlPanEndEvent) {
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) {
                          setState(() {
                            _touchedIndex = null;
                          });
                        }
                      });
                    }
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= 7)
                          return const SizedBox.shrink();
                        final isToday = index == todayWeekday;
                        final isTouched = index == _touchedIndex;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            shortDays[index],
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: isToday || isTouched
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isToday
                                  ? colors.accent
                                  : (isTouched
                                        ? colors.textPrimary
                                        : colors.textSecondary),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: maxY > 10 ? (maxY / 3).roundToDouble() : 3,
                      getTitlesWidget: (value, meta) {
                        if (value <= 0 || value >= meta.max)
                          return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: Text(
                            '${value.toInt()} $unitStr',
                            style: AppTextStyles.labelCaps(
                              color: colors.textSecondary,
                            ).copyWith(fontSize: 9),
                            textAlign: TextAlign.right,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colors.border.withValues(alpha: 0.3),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (index) {
                  final val = convertedData[index];
                  final isTouched = index == _touchedIndex;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: val,
                        color: val > 0
                            ? (isTouched ? colors.textPrimary : colors.accent)
                            : Colors.transparent,
                        width: 14,
                        borderRadius: BorderRadius.circular(7),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: colors.surfaceRaised,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
