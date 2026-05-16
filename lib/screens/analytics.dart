import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../services/user_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _period = 0;
  final _periods = ['Week', 'Month', '3 Months', 'Year'];

  static const _catColors = <String, Color>{
    'Food'         : Color(0xFF00C853),
    'Transport'    : Color(0xFF7C4DFF),
    'Shopping'     : Color(0xFFFF6D00),
    'Bills'        : Color(0xFFFF5252),
    'Health'       : Color(0xFF00BCD4),
    'Education'    : Color(0xFF3D5AFE),
    'Entertainment': Color(0xFFFF4081),
    'Goals'        : Color(0xFF00897B),
    'Savings'      : Color(0xFF00897B),
    'Other'        : Color(0xFF9E9E9E),
  };

  static const _catIcons = <String, IconData>{
    'Food'         : Icons.restaurant_rounded,
    'Transport'    : Icons.directions_car_rounded,
    'Shopping'     : Icons.shopping_bag_rounded,
    'Bills'        : Icons.receipt_long_rounded,
    'Health'       : Icons.favorite_rounded,
    'Education'    : Icons.school_rounded,
    'Entertainment': Icons.movie_rounded,
    'Goals'        : Icons.flag_rounded,
    'Savings'      : Icons.savings_rounded,
    'Other'        : Icons.category_rounded,
  };

  // Get date range based on selected period
  DateTime _startDate() {
    final now = DateTime.now();
    switch (_period) {
      case 0: return now.subtract(const Duration(days: 7));
      case 1: return DateTime(now.year, now.month, 1);
      case 2: return now.subtract(const Duration(days: 90));
      case 3: return DateTime(now.year, 1, 1);
      default: return now.subtract(const Duration(days: 7));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        final currency  = UserService.currency;
        final primary   = Theme.of(context).colorScheme.primary;
        final start     = _startDate();
        final allExp    = provider.onlyExpenses
            .where((e) => e.date.isAfter(start)).toList();
        final hasData   = allExp.isNotEmpty;

        // Category totals
        final catTotals = <String, double>{};
        for (final e in allExp) {
          catTotals[e.category] = (catTotals[e.category] ?? 0) + e.amount;
        }
        final sortedCats = catTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final totalSpent = allExp.fold(0.0, (s, e) => s + e.amount);
        final totalSaved = UserService.savings;

        // 7-day / period daily data for line chart
        final int days = _period == 0 ? 7 : _period == 1 ? 30 : _period == 2 ? 90 : 365;
        final List<double> dailyData = List.generate(
          days > 30 ? 12 : days, // use months for longer periods
          (i) {
            if (days <= 30) {
              final day = DateTime.now().subtract(Duration(days: days - 1 - i));
              return allExp
                  .where((e) =>
                      e.date.year == day.year &&
                      e.date.month == day.month &&
                      e.date.day == day.day)
                  .fold(0.0, (s, e) => s + e.amount);
            } else {
              // Monthly buckets
              final now = DateTime.now();
              final month = DateTime(now.year, now.month - (11 - i), 1);
              final nextMonth = DateTime(month.year, month.month + 1, 1);
              return allExp
                  .where((e) =>
                      e.date.isAfter(month.subtract(const Duration(days: 1))) &&
                      e.date.isBefore(nextMonth))
                  .fold(0.0, (s, e) => s + e.amount);
            }
          },
        );

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
              // Period selector
              _periodSelector(primary),
              const SizedBox(height: 20),

              if (!hasData) ...[
                _emptyState(primary),
              ] else ...[
                // Summary row — real data
                _summaryRow(currency, totalSpent, totalSaved, primary),
                const SizedBox(height: 20),

                // Spending trend line chart
                _card('Spending Trend', _lineChart(dailyData, days, primary)),
                const SizedBox(height: 16),

                // Category breakdown
                if (sortedCats.isNotEmpty) ...[
                  _card('Category Breakdown',
                      _categoryList(sortedCats, totalSpent, currency)),
                  const SizedBox(height: 16),
                ],

                // Monthly comparison bar chart (only for month+ periods)
                if (_period >= 1) ...[
                  _card('Monthly Comparison',
                      _barChart(provider, currency, primary)),
                  const SizedBox(height: 16),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Period selector ───────────────────────────────────────
  Widget _periodSelector(Color primary) {
    return Row(
      children: List.generate(_periods.length, (i) {
        final active = _period == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _period = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: active ? primary : Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: active
                    ? [BoxShadow(color: primary.withValues(alpha: 0.3),
                        blurRadius: 6, offset: const Offset(0, 2))]
                    : [],
              ),
              child: Center(
                child: Text(_periods[i],
                    style: TextStyle(
                        color: active ? Colors.white : Colors.grey,
                        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13)),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Empty state ───────────────────────────────────────────
  Widget _emptyState(Color primary) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bar_chart_rounded, size: 36, color: primary),
          ),
          const SizedBox(height: 16),
          const Text('No data yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Add transactions to see your spending analytics, trends, and category breakdown.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Summary row ───────────────────────────────────────────
  Widget _summaryRow(String currency, double spent, double saved, Color primary) {
    return Row(
      children: [
        _summaryCard('Total Spent', '$currency${spent.toStringAsFixed(0)}',
            const Color(0xFFFF5252)),
        const SizedBox(width: 12),
        _summaryCard('Total Saved', '$currency${saved.toStringAsFixed(0)}', primary),
      ],
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ── Card wrapper ──────────────────────────────────────────
  Widget _card(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 16),
          ClipRect(child: child),
        ],
      ),
    );
  }

  // ── Line chart — real daily/monthly data ──────────────────
  Widget _lineChart(List<double> data, int days, Color primary) {
    if (data.every((v) => v == 0)) {
      return _chartEmpty('No spending data for this period');
    }

    final spots = List.generate(
        data.length, (i) => FlSpot(i.toDouble(), data[i]));

    final labels = days <= 7
        ? ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']
        : days <= 30
            ? List.generate(data.length, (i) => '${i + 1}')
            : ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

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
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: data.length > 10 ? (data.length / 6).ceilToDouble() : 1,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                  return Text(labels[i],
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 9));
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: primary,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [primary.withValues(alpha: 0.2), primary.withValues(alpha: 0.0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bar chart — last 6 months real data ───────────────────
  Widget _barChart(ExpenseProvider provider, String currency, Color primary) {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final m = DateTime(now.year, now.month - (5 - i), 1);
      return m;
    });

    final monthLabels = ['Jan','Feb','Mar','Apr','May','Jun',
                         'Jul','Aug','Sep','Oct','Nov','Dec'];

    final barGroups = <BarChartGroupData>[];
    bool hasAnyData = false;

    for (int i = 0; i < months.length; i++) {
      final m     = months[i];
      final next  = DateTime(m.year, m.month + 1, 1);
      final spent = provider.onlyExpenses
          .where((e) => e.date.isAfter(m.subtract(const Duration(days: 1))) &&
              e.date.isBefore(next))
          .fold(0.0, (s, e) => s + e.amount);
      if (spent > 0) hasAnyData = true;
      barGroups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
              toY: spent / 1000,
              color: const Color(0xFFFF5252),
              width: 14,
              borderRadius: BorderRadius.circular(4)),
        ],
      ));
    }

    if (!hasAnyData) return _chartEmpty('No monthly data yet');

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
                reservedSize: 28,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= months.length) return const SizedBox.shrink();
                  return Text(monthLabels[months[i].month - 1],
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11));
                },
              ),
            ),
          ),
          barGroups: barGroups,
        ),
      ),
    );
  }

  // ── Category list — real data ─────────────────────────────
  Widget _categoryList(
      List<MapEntry<String, double>> cats, double total, String currency) {
    return Column(
      children: cats.map((entry) {
        final color = _catColors[entry.key] ?? Colors.grey;
        final icon  = _catIcons[entry.key] ?? Icons.category_rounded;
        final pct   = total > 0 ? entry.value / total : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key,
                            style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text('$currency${entry.value.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade100,
                              valueColor: AlwaysStoppedAnimation(color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${(pct * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                                fontWeight: FontWeight.w500)),
                      ],
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

  Widget _chartEmpty(String msg) {
    return SizedBox(
      height: 100,
      child: Center(
        child: Text(msg,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
      ),
    );
  }
}
