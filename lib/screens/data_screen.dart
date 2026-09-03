import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/dashboard_data.dart';
import '../services/data_service.dart';

class DataScreen extends StatefulWidget {
  final VoidCallback onBack;
  const DataScreen({super.key, required this.onBack});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  final _dataService = DataService();
  DashboardData? _data;
  bool _loading = false;
  String? _error;
  String? _selectedYear;
  String _selectedMonth = _monthNames[DateTime.now().month - 1];

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _loadCached();
  }

  Future<void> _loadCached() async {
    final cached = await _dataService.loadCached();
    if (cached != null && mounted) {
      setState(() {
        _data = cached;
        _selectedYear = cached.years.isNotEmpty ? cached.years.last : null;
      });
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _dataService.fetch();
      if (!mounted) return;
      setState(() {
        _data = data;
        _selectedYear = data.years.isNotEmpty ? data.years.last : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Color _colorForCategory(String name) {
    for (final c in kCategories) {
      if (c.name == name) return c.color;
    }
    return const Color(0xFF78909C);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Your Expenses', style: Theme.of(context).textTheme.headlineMedium)),
                  IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: widget.onBack, tooltip: 'Back to categories'),
                ],
              ),
              const SizedBox(height: 8),
              _buildFetchBar(),
              const SizedBox(height: 12),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text("Couldn't fetch: $_error", style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
              Expanded(
                child: _data == null
                    ? _buildEmptyState()
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWeeklyCard(_data!),
                            const SizedBox(height: 20),
                            _buildYearSelector(_data!),
                            const SizedBox(height: 16),
                            _buildMonthlySection(_data!),
                            const SizedBox(height: 24),
                            _buildYearlySection(_data!),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFetchBar() {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _loading ? null : _fetch,
          icon: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.refresh_rounded, size: 18),
          label: Text(_loading ? 'Fetching...' : 'Fetch Data'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(width: 12),
        if (_data != null)
          Expanded(
            child: Text('Updated ${_formatLastUpdated(_data!.lastUpdated)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis),
          ),
      ],
    );
  }

  String _formatLastUpdated(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final period = local.hour >= 12 ? 'PM' : 'AM';
    final min = local.minute.toString().padLeft(2, '0');
    return '${local.day}/${local.month} at $h:$min $period';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_chart_outlined_rounded, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('Tap "Fetch Data" to see your expenses', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildWeeklyCard(DashboardData data) {
    final week = data.weekly;
    final entries = week.categories.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('This week', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
                Text(week.weekLabel, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
              Text('₹${week.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF6C63FF))),
            ],
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No expenses logged this week yet.', style: TextStyle(color: Colors.grey)))
          else
            SizedBox(
              height: 160,
              child: BarChart(BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: entries.first.value * 1.25,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= entries.length) return const SizedBox.shrink();
                    final name = entries[i].key;
                    return Padding(padding: const EdgeInsets.only(top: 6), child: Text(name.length > 8 ? '${name.substring(0, 7)}…' : name, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)));
                  })),
                ),
                barGroups: [for (int i = 0; i < entries.length; i++) BarChartGroupData(x: i, barRods: [BarChartRodData(toY: entries[i].value, color: _colorForCategory(entries[i].key), width: 22, borderRadius: BorderRadius.circular(6))])],
              )),
            ),
          const SizedBox(height: 10),
          ...entries.map((e) => _legendRow(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _legendRow(String category, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: _colorForCategory(category), shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(category, style: const TextStyle(fontSize: 13))),
        Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildYearSelector(DashboardData data) {
    final years = data.years.isNotEmpty ? data.years : [DateTime.now().year.toString()];
    return Row(children: [
      const Text('Year:', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(width: 10),
      DropdownButton<String>(value: _selectedYear ?? years.last, items: years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(), onChanged: (v) => setState(() => _selectedYear = v)),
    ]);
  }

  Widget _buildMonthlySection(DashboardData data) {
    final year = _selectedYear ?? (data.years.isNotEmpty ? data.years.last : DateTime.now().year.toString());
    final monthData = data.monthly[year]?[_selectedMonth];
    final categories = monthData?.categories ?? {};
    final total = monthData?.total ?? 0.0;
    final entries = categories.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Monthly breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            DropdownButton<String>(value: _selectedMonth, items: _monthNames.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(), onChanged: (v) => setState(() => _selectedMonth = v!)),
          ]),
          const SizedBox(height: 4),
          Text('₹${total.toStringAsFixed(0)} total in $_selectedMonth', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF6C63FF))),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: Text('No expenses recorded for this month.', style: TextStyle(color: Colors.grey))))
          else ...[
            SizedBox(
              height: 180,
              child: PieChart(PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 36,
                sections: [for (final e in entries) PieChartSectionData(value: e.value, color: _colorForCategory(e.key), title: '${(e.value / total * 100).toStringAsFixed(0)}%', radius: 54, titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white))],
              )),
            ),
            const SizedBox(height: 12),
            ...entries.map((e) => _legendRow(e.key, e.value)),
          ],
        ],
      ),
    );
  }

  Widget _buildYearlySection(DashboardData data) {
    final year = _selectedYear ?? (data.years.isNotEmpty ? data.years.last : DateTime.now().year.toString());
    final yearData = data.yearly[year];
    final monthlyTotals = yearData?.monthlyTotals ?? {};
    final categoryTotals = yearData?.categoryTotals ?? {};
    final total = yearData?.total ?? 0.0;
    final maxMonthly = monthlyTotals.values.isEmpty ? 1.0 : monthlyTotals.values.reduce((a, b) => a > b ? a : b);
    final categoryEntries = categoryTotals.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$year overview', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          Text('₹${total.toStringAsFixed(0)} total this year', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF6C63FF))),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxMonthly * 1.2,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= _monthNames.length) return const SizedBox.shrink();
                  return Padding(padding: const EdgeInsets.only(top: 6), child: Text(_monthNames[i].substring(0, 3), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)));
                })),
              ),
              barGroups: [for (int i = 0; i < _monthNames.length; i++) BarChartGroupData(x: i, barRods: [BarChartRodData(toY: monthlyTotals[_monthNames[i]] ?? 0, color: const Color(0xFF6C63FF), width: 14, borderRadius: BorderRadius.circular(4))])],
            )),
          ),
          const SizedBox(height: 20),
          const Text('By category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (categoryEntries.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No data yet.', style: TextStyle(color: Colors.grey)))
          else ...[
            SizedBox(
              height: 180,
              child: PieChart(PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 36,
                sections: [for (final e in categoryEntries) PieChartSectionData(value: e.value, color: _colorForCategory(e.key), title: '${(e.value / total * 100).toStringAsFixed(0)}%', radius: 54, titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white))],
              )),
            ),
            const SizedBox(height: 12),
            ...categoryEntries.map((e) => _legendRow(e.key, e.value)),
          ],
        ],
      ),
    );
  }
}
