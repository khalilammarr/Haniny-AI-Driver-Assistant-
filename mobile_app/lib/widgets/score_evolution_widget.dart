import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ScoreEvolutionWidget extends StatelessWidget {
  final List<double> scoreHistory;

  const ScoreEvolutionWidget({
    Key? key,
    required this.scoreHistory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Take only last 7 data points to avoid overcrowding
    final displayData = scoreHistory.length > 7
        ? scoreHistory.sublist(scoreHistory.length - 7)
        : scoreHistory;

    // Ensure we have at least 2 points for the chart
    final chartData = displayData.isEmpty
        ? [100.0, 100.0]
        : (displayData.length == 1
            ? [displayData[0], displayData[0]]
            : displayData);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 25,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Évolution (${chartData.length} derniers points)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D4739).withOpacity(0.8),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Moy: ${(chartData.reduce((a, b) => a + b) / chartData.length).toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7FC8A9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: const Color(0xffe7e8ec),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(
                          color: Color(0xff68737d),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        );
                        // Show point number (1, 2, 3, etc.)
                        if (value.toInt() >= 0 &&
                            value.toInt() < chartData.length) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8.0,
                            child: Text('${value.toInt() + 1}', style: style),
                          );
                        }
                        return Container();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Color(0xff67727d),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.left,
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                minX: 0,
                maxX: (chartData.length - 1).toDouble(),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: chartData
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF7FC8A9),
                        Color(0xFF5F7A6A),
                      ],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: const Color(0xFF7FC8A9),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF7FC8A9).withOpacity(0.3),
                          const Color(0xFF7FC8A9).withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
