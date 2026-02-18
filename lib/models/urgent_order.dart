class UrgentOrder {
  final String id;
  final String name;
  final double quantity;
  final String? notes;
  final DateTime date;
  final bool isCompleted;
  final DateTime createdAt;

  UrgentOrder({
    required this.id,
    required this.name,
    required this.quantity,
    this.notes,
    required this.date,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'notes': notes,
      'date': date.toIso8601String(),
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UrgentOrder.fromMap(Map<String, dynamic> map) {
    return UrgentOrder(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      notes: map['notes'],
      date: DateTime.parse(map['date']),
      isCompleted: map['isCompleted'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  UrgentOrder copyWith({
    String? id,
    String? name,
    double? quantity,
    String? notes,
    DateTime? date,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return UrgentOrder(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
