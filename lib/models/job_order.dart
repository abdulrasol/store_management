// طلبات طباعة - نظام حسابات التكلفة

class JobOrder {
  final String id;
  final String orderNumber; // رقم الطلب
  final String customerId;
  final String customerName;
  final String customerPhone;
  
  // تفاصيل الطلب
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final String jobType; // نوع العمل (طباعة, تصميم, طباعة رقمية, إلخ)
  final String status; // الحالة (قيد الانتظار, قيد التنفيذ, مكتمل, مسلّم)
  final String priority; // الأولوية (عادية, عاجلة)
  final String? notes;

  // مواصفات الطباعة
  final String printType; // نوع الطباعة (أوفست, ديجيتال, سلك سكرين)
  final String paperType; // نوع الورق
  final String paperSize; // مقاس الورق
  final int gsm; // وزن الورق
  final int quantityCopies; // عدد النسخ
  final int pagesCount; // عدد الصفحات
  final String colors; // الألوان (أحادي, ملون CMYK, Spot)
  final List<String> finishing; // التشطيب (تجليد, تخريم, قص, طي, تغليف)
  
  // هل يحتاج تصميم؟
  final bool designRequired;
  final double? designCost;
  final int? designHours;

  // حسابات التكلفة
  final MaterialCosts materialCosts;
  final LaborCosts laborCosts;
  final OverheadCosts overheadCosts;
  final Pricing pricing;

  final DateTime createdAt;
  DateTime? updatedAt;

  JobOrder({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.orderDate,
    this.deliveryDate,
    required this.jobType,
    this.status = 'pending', // pending, in_progress, completed, delivered
    this.priority = 'normal',
    this.notes,
    required this.printType,
    required this.paperType,
    required this.paperSize,
    required this.gsm,
    required this.quantityCopies,
    required this.pagesCount,
    required this.colors,
    this.finishing = const [],
    this.designRequired = false,
    this.designCost,
    this.designHours,
    required this.materialCosts,
    required this.laborCosts,
    required this.overheadCosts,
    required this.pricing,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get totalSheetsNeeded => quantityCopies * pagesCount;
  double get totalCost => materialCosts.total + laborCosts.total + overheadCosts.total;
  double get profitAmount => pricing.totalPrice - totalCost - (pricing.vatAmount ?? 0);
  double get profitMargin => totalCost > 0 ? (profitAmount / totalCost) * 100 : 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'orderDate': orderDate.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'jobType': jobType,
      'status': status,
      'priority': priority,
      'notes': notes,
      'printType': printType,
      'paperType': paperType,
      'paperSize': paperSize,
      'gsm': gsm,
      'quantityCopies': quantityCopies,
      'pagesCount': pagesCount,
      'colors': colors,
      'finishing': finishing,
      'designRequired': designRequired,
      'designCost': designCost,
      'designHours': designHours,
      'materialCosts': materialCosts.toMap(),
      'laborCosts': laborCosts.toMap(),
      'overheadCosts': overheadCosts.toMap(),
      'pricing': pricing.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory JobOrder.fromMap(Map<String, dynamic> map) {
    return JobOrder(
      id: map['id'] ?? '',
      orderNumber: map['orderNumber'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      orderDate: DateTime.parse(map['orderDate']),
      deliveryDate: map['deliveryDate'] != null
          ? DateTime.parse(map['deliveryDate'])
          : null,
      jobType: map['jobType'] ?? '',
      status: map['status'] ?? 'pending',
      priority: map['priority'] ?? 'normal',
      notes: map['notes'],
      printType: map['printType'] ?? '',
      paperType: map['paperType'] ?? '',
      paperSize: map['paperSize'] ?? '',
      gsm: map['gsm'] ?? 80,
      quantityCopies: map['quantityCopies'] ?? 0,
      pagesCount: map['pagesCount'] ?? 0,
      colors: map['colors'] ?? '',
      finishing: (map['finishing'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      designRequired: map['designRequired'] ?? false,
      designCost: map['designCost']?.toDouble(),
      designHours: map['designHours'],
      materialCosts: MaterialCosts.fromMap(map['materialCosts'] ?? {}),
      laborCosts: LaborCosts.fromMap(map['laborCosts'] ?? {}),
      overheadCosts: OverheadCosts.fromMap(map['overheadCosts'] ?? {}),
      pricing: Pricing.fromMap(map['pricing'] ?? {}),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  JobOrder copyWith({
    String? id,
    String? orderNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    DateTime? orderDate,
    DateTime? deliveryDate,
    String? jobType,
    String? status,
    String? priority,
    String? notes,
    String? printType,
    String? paperType,
    String? paperSize,
    int? gsm,
    int? quantityCopies,
    int? pagesCount,
    String? colors,
    List<String>? finishing,
    bool? designRequired,
    double? designCost,
    int? designHours,
    MaterialCosts? materialCosts,
    LaborCosts? laborCosts,
    OverheadCosts? overheadCosts,
    Pricing? pricing,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JobOrder(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      orderDate: orderDate ?? this.orderDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      jobType: jobType ?? this.jobType,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      printType: printType ?? this.printType,
      paperType: paperType ?? this.paperType,
      paperSize: paperSize ?? this.paperSize,
      gsm: gsm ?? this.gsm,
      quantityCopies: quantityCopies ?? this.quantityCopies,
      pagesCount: pagesCount ?? this.pagesCount,
      colors: colors ?? this.colors,
      finishing: finishing ?? this.finishing,
      designRequired: designRequired ?? this.designRequired,
      designCost: designCost ?? this.designCost,
      designHours: designHours ?? this.designHours,
      materialCosts: materialCosts ?? this.materialCosts,
      laborCosts: laborCosts ?? this.laborCosts,
      overheadCosts: overheadCosts ?? this.overheadCosts,
      pricing: pricing ?? this.pricing,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

// تكاليف المواد
class MaterialCosts {
  final double paperCost; // تكلفة الورق
  final double inkCost; // تكلفة الحبر
  final double platesCost; // تكلفة البلايتات (للأوفست)
  final double finishingCost; // تكلفة التشطيب
  final double otherMaterialsCost; // مواد أخرى

  MaterialCosts({
    this.paperCost = 0,
    this.inkCost = 0,
    this.platesCost = 0,
    this.finishingCost = 0,
    this.otherMaterialsCost = 0,
  });

  double get total => paperCost + inkCost + platesCost + finishingCost + otherMaterialsCost;

  Map<String, dynamic> toMap() {
    return {
      'paperCost': paperCost,
      'inkCost': inkCost,
      'platesCost': platesCost,
      'finishingCost': finishingCost,
      'otherMaterialsCost': otherMaterialsCost,
    };
  }

  factory MaterialCosts.fromMap(Map<String, dynamic> map) {
    return MaterialCosts(
      paperCost: (map['paperCost'] ?? 0).toDouble(),
      inkCost: (map['inkCost'] ?? 0).toDouble(),
      platesCost: (map['platesCost'] ?? 0).toDouble(),
      finishingCost: (map['finishingCost'] ?? 0).toDouble(),
      otherMaterialsCost: (map['otherMaterialsCost'] ?? 0).toDouble(),
    );
  }
}

// تكاليف العمالة
class LaborCosts {
  final double designCost; // تكلفة التصميم
  final int designHours; // ساعات التصميم
  final double designHourlyRate; // أجر الساعة للتصميم
  
  final double printCost; // تكلفة الطباعة
  final int printHours; // ساعات الطباعة
  final double printHourlyRate; // أجر الساعة للطباعة
  
  final double finishingLaborCost; // تكلفة تشطيب يدوي

  LaborCosts({
    this.designCost = 0,
    this.designHours = 0,
    this.designHourlyRate = 50,
    this.printCost = 0,
    this.printHours = 0,
    this.printHourlyRate = 30,
    this.finishingLaborCost = 0,
  });

  double get total => designCost + printCost + finishingLaborCost;
  double get calculatedDesignCost => designHours * designHourlyRate;
  double get calculatedPrintCost => printHours * printHourlyRate;

  Map<String, dynamic> toMap() {
    return {
      'designCost': designCost,
      'designHours': designHours,
      'designHourlyRate': designHourlyRate,
      'printCost': printCost,
      'printHours': printHours,
      'printHourlyRate': printHourlyRate,
      'finishingLaborCost': finishingLaborCost,
    };
  }

  factory LaborCosts.fromMap(Map<String, dynamic> map) {
    return LaborCosts(
      designCost: (map['designCost'] ?? 0).toDouble(),
      designHours: map['designHours'] ?? 0,
      designHourlyRate: (map['designHourlyRate'] ?? 50).toDouble(),
      printCost: (map['printCost'] ?? 0).toDouble(),
      printHours: map['printHours'] ?? 0,
      printHourlyRate: (map['printHourlyRate'] ?? 30).toDouble(),
      finishingLaborCost: (map['finishingLaborCost'] ?? 0).toDouble(),
    );
  }
}

// التكاليف غير المباشرة (Overhead)
class OverheadCosts {
  final double machineDepreciation; // استهلاك الآلة
  final double electricityCost; // تكلفة الكهرباء
  final double maintenanceAlloc; // صيانة مخصصة
  final double otherOverhead; // تكاليف أخرى

  OverheadCosts({
    this.machineDepreciation = 0,
    this.electricityCost = 0,
    this.maintenanceAlloc = 0,
    this.otherOverhead = 0,
  });

  double get total => machineDepreciation + electricityCost + maintenanceAlloc + otherOverhead;

  Map<String, dynamic> toMap() {
    return {
      'machineDepreciation': machineDepreciation,
      'electricityCost': electricityCost,
      'maintenanceAlloc': maintenanceAlloc,
      'otherOverhead': otherOverhead,
    };
  }

  factory OverheadCosts.fromMap(Map<String, dynamic> map) {
    return OverheadCosts(
      machineDepreciation: (map['machineDepreciation'] ?? 0).toDouble(),
      electricityCost: (map['electricityCost'] ?? 0).toDouble(),
      maintenanceAlloc: (map['maintenanceAlloc'] ?? 0).toDouble(),
      otherOverhead: (map['otherOverhead'] ?? 0).toDouble(),
    );
  }
}

// التسعير والربح
class Pricing {
  final double totalCost; // التكلفة الإجمالية
  final double profitMargin; // نسبة الربح (%)
  final double profitAmount; // مبلغ الربح
  final double subtotal; // المجموع الفرعي
  final double vatRate; // نسبة الضريبة (%)
  final double? vatAmount; // مبلغ الضريبة
  final double totalPrice; // السعر النهائي
  final double paidAmount; // المبلغ المدفوع
  final double remainingAmount; // المتبقي

  Pricing({
    this.totalCost = 0,
    this.profitMargin = 30, // 30% افتراضي
    this.profitAmount = 0,
    this.subtotal = 0,
    this.vatRate = 5, // 5% افتراضي
    this.vatAmount,
    this.totalPrice = 0,
    this.paidAmount = 0,
    this.remainingAmount = 0,
  });

  double get calculatedProfit => totalCost * (profitMargin / 100);
  double get calculatedSubtotal => totalCost + calculatedProfit;
  double get calculatedVat => calculatedSubtotal * (vatRate / 100);
  double get calculatedTotalPrice => calculatedSubtotal + calculatedVat;
  double get calculatedRemaining => totalPrice - paidAmount;

  Map<String, dynamic> toMap() {
    return {
      'totalCost': totalCost,
      'profitMargin': profitMargin,
      'profitAmount': profitAmount,
      'subtotal': subtotal,
      'vatRate': vatRate,
      'vatAmount': vatAmount,
      'totalPrice': totalPrice,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
    };
  }

  factory Pricing.fromMap(Map<String, dynamic> map) {
    return Pricing(
      totalCost: (map['totalCost'] ?? 0).toDouble(),
      profitMargin: (map['profitMargin'] ?? 30).toDouble(),
      profitAmount: (map['profitAmount'] ?? 0).toDouble(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      vatRate: (map['vatRate'] ?? 5).toDouble(),
      vatAmount: map['vatAmount']?.toDouble(),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      remainingAmount: (map['remainingAmount'] ?? 0).toDouble(),
    );
  }

  // حساب تلقائي للتسعير
  static Pricing calculate({
    required double totalCost,
    double profitMargin = 30,
    double vatRate = 5,
    double paidAmount = 0,
  }) {
    final profitAmount = totalCost * (profitMargin / 100);
    final subtotal = totalCost + profitAmount;
    final vatAmount = subtotal * (vatRate / 100);
    final totalPrice = subtotal + vatAmount;
    final remainingAmount = totalPrice - paidAmount;

    return Pricing(
      totalCost: totalCost,
      profitMargin: profitMargin,
      profitAmount: profitAmount,
      subtotal: subtotal,
      vatRate: vatRate,
      vatAmount: vatAmount,
      totalPrice: totalPrice,
      paidAmount: paidAmount,
      remainingAmount: remainingAmount,
    );
  }
}

// تلخيص طلبات الطباعة
class JobOrderSummary {
  final int totalOrders;
  final int pendingOrders;
  final int completedOrders;
  final int deliveredOrders;
  final double totalRevenue;
  final double totalCosts;
  final double totalProfit;
  final double averageProfitMargin;
  final int urgentOrders;

  JobOrderSummary({
    this.totalOrders = 0,
    this.pendingOrders = 0,
    this.completedOrders = 0,
    this.deliveredOrders = 0,
    this.totalRevenue = 0,
    this.totalCosts = 0,
    this.totalProfit = 0,
    this.averageProfitMargin = 0,
    this.urgentOrders = 0,
  });

  double get averageOrderValue => totalOrders > 0 ? totalRevenue / totalOrders : 0;
  double get completionRate => totalOrders > 0 ? (deliveredOrders / totalOrders) * 100 : 0;
}
