class Purchase {
  final String id;
  final String supplierName;
  final String receiptNumber;
  final DateTime purchaseDate;
  // final List<PurchaseItem> items; // Removed
  final double amount;
  final String? categoryId; // Added category to main purchase
  final String paymentStatus; // 'paid', 'partial', 'unpaid'
  final String? notes;
  final DateTime createdAt;

  Purchase({
    required this.id,
    required this.supplierName,
    required this.receiptNumber,
    required this.purchaseDate,
    required this.amount,
    this.categoryId,
    this.paymentStatus = 'paid',
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get totalAmount => amount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplierName': supplierName,
      'receiptNumber': receiptNumber,
      'purchaseDate': purchaseDate.toIso8601String(),
      'amount': amount,
      'categoryId': categoryId,
      'paymentStatus': paymentStatus,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map) {
    // Migration logic for old data with items
    double amount = (map['amount'] ?? 0).toDouble();
    if (amount == 0 && map['items'] != null) {
      final items = (map['items'] as List<dynamic>)
          .map((item) => PurchaseItem.fromMap(item))
          .toList();
      amount = items.fold(0, (sum, item) => sum + item.total);
    }

    return Purchase(
      id: map['id'] ?? '',
      supplierName: map['supplierName'] ?? '',
      receiptNumber: map['receiptNumber'] ?? '',
      purchaseDate: DateTime.parse(map['purchaseDate']),
      amount: amount,
      categoryId: map['categoryId'],
      paymentStatus: map['paymentStatus'] ?? 'paid',
      notes: map['notes'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Purchase copyWith({
    String? id,
    String? supplierName,
    String? receiptNumber,
    DateTime? purchaseDate,
    double? amount,
    String? categoryId,
    String? paymentStatus,
    String? notes,
    DateTime? createdAt,
  }) {
    return Purchase(
      id: id ?? this.id,
      supplierName: supplierName ?? this.supplierName,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PurchaseCategory {
  final String id;
  final String name;

  PurchaseCategory({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory PurchaseCategory.fromMap(Map<String, dynamic> map) {
    return PurchaseCategory(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
    );
  }
}

class PurchaseItem {
  final String itemName;
  final String? categoryId;
  final double quantity;
  final double unitPrice;

  PurchaseItem({
    required this.itemName,
    this.categoryId,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'categoryId': categoryId,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      itemName: map['itemName'] ?? '',
      categoryId: map['categoryId'],
      quantity: (map['quantity'] ?? 0).toDouble(),
      unitPrice: (map['unitPrice'] ?? 0).toDouble(),
    );
  }
}
