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

class WeekData {
  final String weekLabel;
  final Map<String, double> categories;
  final double total;
  WeekData({required this.weekLabel, required this.categories, required this.total});
  factory WeekData.fromJson(Map<String, dynamic> json) => WeekData(
        weekLabel: json['weekLabel'] as String? ?? '',
        categories: (json['categories'] as Map<String, dynamic>? ?? {}).map((k, v) => MapEntry(k, (v as num).toDouble())),
        total: (json['total'] as num?)?.toDouble() ?? 0,
      );
}

class DashboardData {
  final List<String> years;
  final Map<String, Map<String, MonthData>> monthly;
  final Map<String, YearData> yearly;
  final WeekData weekly;
  final DateTime lastUpdated;

  DashboardData({required this.years, required this.monthly, required this.yearly, required this.weekly, required this.lastUpdated});

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final monthlyRaw = json['monthly'] as Map<String, dynamic>? ?? {};
    final monthly = monthlyRaw.map((year, monthsJson) => MapEntry(
          year,
          (monthsJson as Map<String, dynamic>).map((month, data) => MapEntry(month, MonthData.fromJson(data))),
        ));
    final yearlyRaw = json['yearly'] as Map<String, dynamic>? ?? {};
    final yearly = yearlyRaw.map((year, data) => MapEntry(year, YearData.fromJson(data)));

    return DashboardData(
      years: List<String>.from(json['years'] ?? []),
      monthly: monthly,
      yearly: yearly,
      weekly: WeekData.fromJson(json['weekly'] ?? {}),
      lastUpdated: DateTime.tryParse(json['lastUpdated'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'years': years,
        'monthly': monthly.map((y, m) => MapEntry(y, m.map((mo, d) => MapEntry(mo, {'total': d.total, 'categories': d.categories})))),
        'yearly': yearly.map((y, d) => MapEntry(y, {'monthlyTotals': d.monthlyTotals, 'categoryTotals': d.categoryTotals, 'total': d.total})),
        'weekly': {'weekLabel': weekly.weekLabel, 'categories': weekly.categories, 'total': weekly.total},
        'lastUpdated': lastUpdated.toIso8601String(),
      };
}
