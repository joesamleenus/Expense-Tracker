class MonthData {
  final double total;
  final Map<String, double> categories;
  MonthData({required this.total, required this.categories});
  factory MonthData.fromJson(Map<String, dynamic> json) => MonthData(
        total: (json['total'] as num).toDouble(),
        categories: (json['categories'] as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toDouble())),
      );
}

class YearData {
  final Map<String, double> monthlyTotals;
  final Map<String, double> categoryTotals;
  final double total;
  YearData({required this.monthlyTotals, required this.categoryTotals, required this.total});
  factory YearData.fromJson(Map<String, dynamic> json) => YearData(
        monthlyTotals: (json['monthlyTotals'] as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toDouble())),
        categoryTotals: (json['categoryTotals'] as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toDouble())),
        total: (json['total'] as num).toDouble(),
      );
}

class WeekEntry {
  final String weekStart;
  final String weekLabel;
  final double total;
  final Map<String, double> categories;
  WeekEntry({required this.weekStart, required this.weekLabel, required this.total, required this.categories});
  factory WeekEntry.fromJson(Map<String, dynamic> json) => WeekEntry(
        weekStart: json['weekStart'] as String? ?? '',
        weekLabel: json['weekLabel'] as String? ?? '',
        total: (json['total'] as num?)?.toDouble() ?? 0,
        categories: (json['categories'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, (v as num).toDouble())),
      );
  Map<String, dynamic> toJson() => {'weekStart': weekStart, 'weekLabel': weekLabel, 'total': total, 'categories': categories};
}

class LogEntry {
  final String id;
  final String display;
  final String category;
  final double amount;
  final String notes;
  LogEntry({required this.id, required this.display, required this.category, required this.amount, required this.notes});
  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
        id: json['id'] as String? ?? '',
        display: json['display'] as String? ?? '',
        category: json['category'] as String? ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        notes: json['notes'] as String? ?? '',
      );
  Map<String, dynamic> toJson() => {'id': id, 'display': display, 'category': category, 'amount': amount, 'notes': notes};
}

class DashboardData {
  final List<String> years;
  final Map<String, Map<String, MonthData>> monthly;
  final Map<String, YearData> yearly;
  final Map<String, Map<String, List<WeekEntry>>> weekly;
  final Map<String, double> budgets;
  final List<LogEntry> log;
  final DateTime lastUpdated;

  DashboardData({
    required this.years,
    required this.monthly,
    required this.yearly,
    required this.weekly,
    required this.budgets,
    required this.log,
    required this.lastUpdated,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final monthlyRaw = json['monthly'] as Map<String, dynamic>? ?? {};
    final monthly = monthlyRaw.map((year, monthsJson) => MapEntry(
          year,
          (monthsJson as Map<String, dynamic>).map((month, data) => MapEntry(month, MonthData.fromJson(data))),
        ));

    final yearlyRaw = json['yearly'] as Map<String, dynamic>? ?? {};
    final yearly = yearlyRaw.map((year, data) => MapEntry(year, YearData.fromJson(data)));

    final weeklyRaw = json['weekly'] as Map<String, dynamic>? ?? {};
    final weekly = weeklyRaw.map((year, monthsJson) => MapEntry(
          year,
          (monthsJson as Map<String, dynamic>).map((month, list) => MapEntry(
                month,
                (list as List).map((w) => WeekEntry.fromJson(w as Map<String, dynamic>)).toList(),
              )),
        ));

    final budgetsRaw = json['budgets'] as Map<String, dynamic>? ?? {};
    final logRaw = json['log'] as List<dynamic>? ?? [];

    return DashboardData(
      years: List<String>.from(json['years'] ?? []),
      monthly: monthly,
      yearly: yearly,
      weekly: weekly,
      budgets: budgetsRaw.map((k, v) => MapEntry(k, (v as num).toDouble())),
      log: logRaw.map((e) => LogEntry.fromJson(e as Map<String, dynamic>)).toList(),
      lastUpdated: DateTime.tryParse(json['lastUpdated'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'years': years,
        'monthly': monthly.map((y, m) => MapEntry(y, m.map((mo, d) => MapEntry(mo, {'total': d.total, 'categories': d.categories})))),
        'yearly': yearly.map((y, d) => MapEntry(y, {'monthlyTotals': d.monthlyTotals, 'categoryTotals': d.categoryTotals, 'total': d.total})),
        'weekly': weekly.map((y, m) => MapEntry(y, m.map((mo, list) => MapEntry(mo, list.map((w) => w.toJson()).toList())))),
        'budgets': budgets,
        'log': log.map((e) => e.toJson()).toList(),
        'lastUpdated': lastUpdated.toIso8601String(),
      };
}
