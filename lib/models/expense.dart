class Expense {
  final String category;
  final double amount;
  final String notes;
  final DateTime createdAt;

  Expense({
    required this.category,
    required this.amount,
    required this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'amount': amount,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        category: json['category'] as String,
        amount: (json['amount'] as num).toDouble(),
        notes: json['notes'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
