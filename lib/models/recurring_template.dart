class RecurringTemplate {
  final String id;
  final String category;
  final double amount;
  final String notes;
  String? lastLoggedMonth;

  RecurringTemplate({
    required this.id,
    required this.category,
    required this.amount,
    required this.notes,
    this.lastLoggedMonth,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'amount': amount,
        'notes': notes,
        'lastLoggedMonth': lastLoggedMonth,
      };

  factory RecurringTemplate.fromJson(Map<String, dynamic> json) => RecurringTemplate(
        id: json['id'] as String,
        category: json['category'] as String,
        amount: (json['amount'] as num).toDouble(),
        notes: json['notes'] as String? ?? '',
        lastLoggedMonth: json['lastLoggedMonth'] as String?,
      );
}
