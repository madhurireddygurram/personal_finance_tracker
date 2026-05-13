import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _period = 0;
  final _periods = ['Week', 'Month', '3 Months', 'Year'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _periodSelector(),
          const SizedBox(height: 20),
          _summaryRow(),
          const SizedBox(height: 20),
          _card('Spending Trend', _lineChart()),
          const SizedBox(height: 16),
          _card('Monthly Comparison', _barChart()),
          const SizedBox(height: 16),
          _card('Category Breakdown', _categoryList()),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _periodSelector() {
    return Row(
      children: List.generate(_periods.length, (i) {
        final active = _period == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _period = i),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: active ? Theme.of(context).colorScheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(_periods[i],
                    style: TextStyle(
                        color: active ? Colors.white : Colors.grey,
                        fontWeight: active
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 13)),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _summaryRow() {
    return Row(
      children: [
        _summaryCard('Total Spent', '₹10,000', const Color(0xFFFF5252)),
        const SizedBox(width: 12),
        _summaryCard('Total Saved', '₹10,000', Theme.of(context).colorScheme.primary),
      ],
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 16),
          ClipRect(child: child),
        ],
      ),
    );
  }

  Widget _lineChart() {
    return SizedBox(
      height: 190,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.grey.shade100, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  final i = v.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                  return Text(labels[i],
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 10));
                },
                reservedSize: 28,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 200),
                FlSpot(1, 450),
                FlSpot(2, 300),
                FlSpot(3, 700),
                FlSpot(4, 400),
                FlSpot(5, 600),
                FlSpot(6, 350),
              ],
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barChart() {
    return SizedBox(
      height: 190,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  const labels = ['Sep', 'Oct', 'Nov', 'Dec', 'Jan'];
                  final i = v.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                  return Text(labels[i],
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 11));
                },
                reservedSize: 28,
              ),
            ),
          ),
          barGroups: [
            _bar(0, 8000, 12000),
            _bar(1, 9500, 15000),
            _bar(2, 7000, 11000),
            _bar(3, 12000, 18000),
            _bar(4, 10000, 20000),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _bar(int x, double expense, double income) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
            toY: expense / 1000,
            color: const Color(0xFFFF5252),
            width: 10,
            borderRadius: BorderRadius.circular(4)),
        BarChartRodData(
            toY: income / 1000,
            color: Theme.of(context).colorScheme.primary,
            width: 10,
            borderRadius: BorderRadius.circular(4)),
      ],
    );
  }

  Widget _categoryList() {
    final cats = [
      {'name': 'Food', 'icon': '🍔', 'amount': '₹3,500', 'pct': 0.35, 'color': 0xFF00C853},
      {'name': 'Transport', 'icon': '🚕', 'amount': '₹2,500', 'pct': 0.25, 'color': 0xFF7C4DFF},
      {'name': 'Shopping', 'icon': '🛍️', 'amount': '₹2,000', 'pct': 0.20, 'color': 0xFFFF6D00},
      {'name': 'Bills', 'icon': '📄', 'amount': '₹1,500', 'pct': 0.15, 'color': 0xFF00BCD4},
      {'name': 'Other', 'icon': '📦', 'amount': '₹500', 'pct': 0.05, 'color': 0xFFFF5252},
    ];
    return Column(
      children: cats.map((c) {
        final color = Color(c['color'] as int);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(c['icon'] as String,
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(c['name'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500)),
                        Text(c['amount'] as String,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: c['pct'] as double,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

