// إدارة المخزون للمطبعة

// الأوراق
class PaperStock {
  final String id;
  final String paperType; // نوع الورق
  final String paperSize; // المقاس (A4, A3, A2, A1, A0)
  final int gsm; // الوزن بالجرام (70, 80, 100, 120, 200, 300)
  final String coating; // نوع الطلاء (لامع/مط/بدون)
  int quantitySheets; // الكمية بالأوراق
  double quantityReams; // الكمية بالرزم
  final double unitCost; // تكلفة الورقة الواحدة
  final String supplier;
  final int reorderLevel; // مستوى إعادة الطلب
  final DateTime lastPurchaseDate;
  final DateTime createdAt;

  PaperStock({
    required this.id,
    required this.paperType,
    required this.paperSize,
    required this.gsm,
    required this.coating,
    this.quantitySheets = 0,
    this.quantityReams = 0,
    required this.unitCost,
    required this.supplier,
    this.reorderLevel = 500,
    DateTime? lastPurchaseDate,
    DateTime? createdAt,
  })  : lastPurchaseDate = lastPurchaseDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  double get totalValue => quantitySheets * unitCost;
  bool get isLowStock => quantitySheets <= reorderLevel;
  String get displayName => '$paperType $paperSize ${gsm}gsm ($coating)';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'paperType': paperType,
      'paperSize': paperSize,
      'gsm': gsm,
      'coating': coating,
      'quantitySheets': quantitySheets,
      'quantityReams': quantityReams,
      'unitCost': unitCost,
      'supplier': supplier,
      'reorderLevel': reorderLevel,
      'lastPurchaseDate': lastPurchaseDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PaperStock.fromMap(Map<String, dynamic> map) {
    return PaperStock(
      id: map['id'] ?? '',
      paperType: map['paperType'] ?? '',
      paperSize: map['paperSize'] ?? '',
      gsm: map['gsm'] ?? 0,
      coating: map['coating'] ?? 'بدون',
      quantitySheets: map['quantitySheets'] ?? 0,
      quantityReams: (map['quantityReams'] ?? 0).toDouble(),
      unitCost: (map['unitCost'] ?? 0).toDouble(),
      supplier: map['supplier'] ?? '',
      reorderLevel: map['reorderLevel'] ?? 500,
      lastPurchaseDate: map['lastPurchaseDate'] != null
          ? DateTime.parse(map['lastPurchaseDate'])
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  PaperStock copyWith({
    String? id,
    String? paperType,
    String? paperSize,
    int? gsm,
    String? coating,
    int? quantitySheets,
    double? quantityReams,
    double? unitCost,
    String? supplier,
    int? reorderLevel,
    DateTime? lastPurchaseDate,
    DateTime? createdAt,
  }) {
    return PaperStock(
      id: id ?? this.id,
      paperType: paperType ?? this.paperType,
      paperSize: paperSize ?? this.paperSize,
      gsm: gsm ?? this.gsm,
      coating: coating ?? this.coating,
      quantitySheets: quantitySheets ?? this.quantitySheets,
      quantityReams: quantityReams ?? this.quantityReams,
      unitCost: unitCost ?? this.unitCost,
      supplier: supplier ?? this.supplier,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      lastPurchaseDate: lastPurchaseDate ?? this.lastPurchaseDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// الأحبار
class InkStock {
  final String id;
  final String inkType; // نوع الحبر (CMYK, Spot, Pantone)
  final String color; // اللون (Cyan, Magenta, Yellow, Black, Spot Red, etc.)
  final double quantityMl; // الكمية بالمل
  final double unitCostPerMl; // التكلفة لكل مل
  final List<String> compatibleMachines; // الآلات المتوافقة
  final String supplier;
  final int reorderLevelMl;
  final DateTime lastPurchaseDate;
  final DateTime createdAt;

  InkStock({
    required this.id,
    required this.inkType,
    required this.color,
    this.quantityMl = 0,
    required this.unitCostPerMl,
    this.compatibleMachines = const [],
    required this.supplier,
    this.reorderLevelMl = 500,
    DateTime? lastPurchaseDate,
    DateTime? createdAt,
  })  : lastPurchaseDate = lastPurchaseDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  double get totalValue => quantityMl * unitCostPerMl;
  double get quantityLiters => quantityMl / 1000;
  bool get isLowStock => quantityMl <= reorderLevelMl;
  String get displayName => '$color ($inkType)';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inkType': inkType,
      'color': color,
      'quantityMl': quantityMl,
      'unitCostPerMl': unitCostPerMl,
      'compatibleMachines': compatibleMachines,
      'supplier': supplier,
      'reorderLevelMl': reorderLevelMl,
      'lastPurchaseDate': lastPurchaseDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory InkStock.fromMap(Map<String, dynamic> map) {
    return InkStock(
      id: map['id'] ?? '',
      inkType: map['inkType'] ?? '',
      color: map['color'] ?? '',
      quantityMl: (map['quantityMl'] ?? 0).toDouble(),
      unitCostPerMl: (map['unitCostPerMl'] ?? 0).toDouble(),
      compatibleMachines: (map['compatibleMachines'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      supplier: map['supplier'] ?? '',
      reorderLevelMl: map['reorderLevelMl'] ?? 500,
      lastPurchaseDate: map['lastPurchaseDate'] != null
          ? DateTime.parse(map['lastPurchaseDate'])
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  InkStock copyWith({
    String? id,
    String? inkType,
    String? color,
    double? quantityMl,
    double? unitCostPerMl,
    List<String>? compatibleMachines,
    String? supplier,
    int? reorderLevelMl,
    DateTime? lastPurchaseDate,
    DateTime? createdAt,
  }) {
    return InkStock(
      id: id ?? this.id,
      inkType: inkType ?? this.inkType,
      color: color ?? this.color,
      quantityMl: quantityMl ?? this.quantityMl,
      unitCostPerMl: unitCostPerMl ?? this.unitCostPerMl,
      compatibleMachines: compatibleMachines ?? this.compatibleMachines,
      supplier: supplier ?? this.supplier,
      reorderLevelMl: reorderLevelMl ?? this.reorderLevelMl,
      lastPurchaseDate: lastPurchaseDate ?? this.lastPurchaseDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// قطع الغيار
class SparePart {
  final String id;
  final String partName; // اسم القطعة
  final String partNumber; // رقم القطعة
  final String machineModel; // موديل الآلة
  final int quantity; // الكمية
  final double unitCost; // التكلفة
  final int? lifespanHours; // العمر الافتراضي بالساعات (اختياري)
  final String supplier;
  final int reorderLevel;
  final DateTime createdAt;

  SparePart({
    required this.id,
    required this.partName,
    required this.partNumber,
    required this.machineModel,
    this.quantity = 0,
    required this.unitCost,
    this.lifespanHours,
    required this.supplier,
    this.reorderLevel = 2,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get totalValue => quantity * unitCost;
  bool get isLowStock => quantity <= reorderLevel;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partName': partName,
      'partNumber': partNumber,
      'machineModel': machineModel,
      'quantity': quantity,
      'unitCost': unitCost,
      'lifespanHours': lifespanHours,
      'supplier': supplier,
      'reorderLevel': reorderLevel,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SparePart.fromMap(Map<String, dynamic> map) {
    return SparePart(
      id: map['id'] ?? '',
      partName: map['partName'] ?? '',
      partNumber: map['partNumber'] ?? '',
      machineModel: map['machineModel'] ?? '',
      quantity: map['quantity'] ?? 0,
      unitCost: (map['unitCost'] ?? 0).toDouble(),
      lifespanHours: map['lifespanHours'],
      supplier: map['supplier'] ?? '',
      reorderLevel: map['reorderLevel'] ?? 2,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  SparePart copyWith({
    String? id,
    String? partName,
    String? partNumber,
    String? machineModel,
    int? quantity,
    double? unitCost,
    int? lifespanHours,
    String? supplier,
    int? reorderLevel,
    DateTime? createdAt,
  }) {
    return SparePart(
      id: id ?? this.id,
      partName: partName ?? this.partName,
      partNumber: partNumber ?? this.partNumber,
      machineModel: machineModel ?? this.machineModel,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      lifespanHours: lifespanHours ?? this.lifespanHours,
      supplier: supplier ?? this.supplier,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// تلخيص المخزون
class InventorySummary {
  final double totalPaperValue;
  final double totalInkValue;
  final double totalSparePartsValue;
  final int lowStockPaperCount;
  final int lowStockInkCount;
  final int lowStockSparePartsCount;

  InventorySummary({
    this.totalPaperValue = 0,
    this.totalInkValue = 0,
    this.totalSparePartsValue = 0,
    this.lowStockPaperCount = 0,
    this.lowStockInkCount = 0,
    this.lowStockSparePartsCount = 0,
  });

  double get totalInventoryValue =>
      totalPaperValue + totalInkValue + totalSparePartsValue;
  int get totalLowStockCount =>
      lowStockPaperCount + lowStockInkCount + lowStockSparePartsCount;
}
