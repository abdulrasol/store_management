import 'dart:convert';

class SalaryTransaction {
  final String id;
  final String employeeId;
  final String employeeName;
  final String type; // 'withdraw' (سحب) or 'deduction' (خصم) or 'bonus' (مكافأة)
  final double amount;
  final DateTime date;
  final String? notes;

  SalaryTransaction({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.type,
    required this.amount,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory SalaryTransaction.fromMap(Map<String, dynamic> map) {
    return SalaryTransaction(
      id: map['id'] ?? '',
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      type: map['type'] ?? 'withdraw',
      amount: (map['amount'] ?? 0).toDouble(),
      date: DateTime.parse(map['date']),
      notes: map['notes'],
    );
  }

  String toJson() => json.encode(toMap());

  factory SalaryTransaction.fromJson(String source) =>
      SalaryTransaction.fromMap(json.decode(source));
}
