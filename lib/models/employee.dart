// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Employee {
  final String id;
  final String name;
  final String phone;
  final String jobTitle;
  final double salary;
  final String status; // 'active', 'vacation', etc.
  final String? createdAt;

  Employee({
    required this.id,
    required this.name,
    required this.phone,
    required this.jobTitle,
    required this.salary,
    this.status = 'active',
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'phone': phone,
      'jobTitle': jobTitle,
      'salary': salary,
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      jobTitle: map['jobTitle'] as String,
      salary: (map['salary'] as num).toDouble(),
      status: map['status'] as String? ?? 'active',
      createdAt: map['createdAt'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory Employee.fromJson(String source) =>
      Employee.fromMap(json.decode(source) as Map<String, dynamic>);

  Employee copyWith({
    String? id,
    String? name,
    String? phone,
    String? jobTitle,
    double? salary,
    String? status,
    String? createdAt,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      jobTitle: jobTitle ?? this.jobTitle,
      salary: salary ?? this.salary,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
