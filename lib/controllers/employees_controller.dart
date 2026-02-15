// lib/controllers/employees_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:store_management/controllers/database_controller.dart';
import 'package:store_management/models/employee.dart';
import 'package:store_management/models/salary_transaction.dart';

class EmployeesController extends GetxController {
  final DatabaseController databaseController = Get.find<DatabaseController>();
  
  var employees = <Employee>[].obs;
  var filteredEmployees = <Employee>[].obs;
  var employeeTransactions = <SalaryTransaction>[].obs;
  
  TextEditingController searchController = TextEditingController();
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadEmployees();
  }


  Future<void> loadEmployees() async {
    isLoading.value = true;
    try {
      final data = await databaseController.getEmployees();
      employees.value = data;
      filterEmployees(searchController.text);
    } catch (e) {
      debugPrint('Error loading employees: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void filterEmployees(String query) {
    if (query.isEmpty) {
      filteredEmployees.value = employees;
    } else {
      filteredEmployees.value = employees.where((e) {
        return e.name.toLowerCase().contains(query.toLowerCase()) || 
               e.phone.contains(query) || 
               e.jobTitle.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
  }

  Future<void> addEmployee(Employee emp) async {
    isLoading.value = true;
    try {
      await databaseController.addEmployee(emp);
      await loadEmployees();
    } catch (e) {
      Get.snackbar('Error'.tr, 'Failed to add employee'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateEmployee(Employee emp) async {
    isLoading.value = true;
    try {
      await databaseController.updateEmployee(emp);
      await loadEmployees();
    } catch (e) {
      Get.snackbar('Error'.tr, 'Failed to update employee'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteEmployee(String id) async {
    try {
      await databaseController.deleteEmployee(id);
      await loadEmployees();
    } catch (e) {
      Get.snackbar('Error'.tr, 'Failed to delete employee'.tr);
    }
  }
  Future<void> loadEmployeeTransactions(String employeeId) async {
    try {
      final data = await databaseController.getEmployeeTransactions(employeeId);
      employeeTransactions.value = data;
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    }
  }

  Future<void> addTransaction(SalaryTransaction transaction) async {
    try {
      await databaseController.addSalaryTransaction(transaction);
      // Refresh transactions list if currently viewing that employee
      await loadEmployeeTransactions(transaction.employeeId);
      Get.back();
      Get.snackbar('Success'.tr, 'Transaction added successfully'.tr, backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error'.tr, 'Failed to add transaction'.tr, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> deleteTransaction(String id, String employeeId) async {
    try {
      await databaseController.deleteSalaryTransaction(id);
      await loadEmployeeTransactions(employeeId);
      Get.back(); // Close dialog if open, or just refresh
      Get.snackbar('Success'.tr, 'Transaction deleted'.tr, backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Error'.tr, 'Failed to delete transaction'.tr, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
  
  int get activeCount => employees.where((e) => e.status == 'active').length;
}
