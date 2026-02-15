class Employee {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? notes;
  final DateTime createdAt;

  Employee({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'],
      notes: map['notes'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Employee copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? notes,
    DateTime? createdAt,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Salary {
  final String id;
  final String employeeId;
  final String employeeName;
  final DateTime month;
  final double baseSalary;
  final double bonus;
  final double deductions;
  final String? notes;
  final DateTime createdAt;

  Salary({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.month,
    required this.baseSalary,
    this.bonus = 0,
    this.deductions = 0,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get totalSalary => baseSalary + bonus - deductions;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'month': month.toIso8601String(),
      'baseSalary': baseSalary,
      'bonus': bonus,
      'deductions': deductions,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Salary.fromMap(Map<String, dynamic> map) {
    return Salary(
      id: map['id'] ?? '',
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      month: DateTime.parse(map['month']),
      baseSalary: (map['baseSalary'] ?? 0).toDouble(),
      bonus: (map['bonus'] ?? 0).toDouble(),
      deductions: (map['deductions'] ?? 0).toDouble(),
      notes: map['notes'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Salary copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    DateTime? month,
    double? baseSalary,
    double? bonus,
    double? deductions,
    String? notes,
    DateTime? createdAt,
  }) {
    return Salary(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      month: month ?? this.month,
      baseSalary: baseSalary ?? this.baseSalary,
      bonus: bonus ?? this.bonus,
      deductions: deductions ?? this.deductions,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class SalaryAdvance {
  final String id;
  final String employeeId;
  final String employeeName;
  final double amount;
  final String? reason;
  final DateTime requestDate;
  final bool isPaidOff;
  final DateTime? paidOffDate;
  final String? salaryId;
  final DateTime createdAt;

  SalaryAdvance({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.amount,
    this.reason,
    required this.requestDate,
    this.isPaidOff = false,
    this.paidOffDate,
    this.salaryId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'amount': amount,
      'reason': reason,
      'requestDate': requestDate.toIso8601String(),
      'isPaidOff': isPaidOff,
      'paidOffDate': paidOffDate?.toIso8601String(),
      'salaryId': salaryId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SalaryAdvance.fromMap(Map<String, dynamic> map) {
    return SalaryAdvance(
      id: map['id'] ?? '',
      employeeId: map['employeeId'] ?? '',
      employeeName: map['employeeName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      reason: map['reason'],
      requestDate: DateTime.parse(map['requestDate']),
      isPaidOff: map['isPaidOff'] ?? false,
      paidOffDate: map['paidOffDate'] != null
          ? DateTime.parse(map['paidOffDate'])
          : null,
      salaryId: map['salaryId'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  SalaryAdvance copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    double? amount,
    String? reason,
    DateTime? requestDate,
    bool? isPaidOff,
    DateTime? paidOffDate,
    String? salaryId,
    DateTime? createdAt,
  }) {
    return SalaryAdvance(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      requestDate: requestDate ?? this.requestDate,
      isPaidOff: isPaidOff ?? this.isPaidOff,
      paidOffDate: paidOffDate ?? this.paidOffDate,
      salaryId: salaryId ?? this.salaryId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
