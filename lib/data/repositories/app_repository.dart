import 'package:drift/drift.dart';
import '../local/database.dart';

class AppRepository {
  final AppDatabase db;
  AppRepository(this.db);

  // ---------- کسب‌وکار ----------
  Future<void> saveBusinessSettings({
    required String businessName,
    required String jobType,
  }) async {
    await db.into(db.businessSettings).insert(
          BusinessSettingsCompanion.insert(
            businessName: businessName,
            jobType: jobType,
          ),
        );
  }

  // ---------- مشتری ----------
  Future<int> addCustomer({
    required String name,
    required String phone,
    String? address,
  }) {
    return db.into(db.customers).insert(
          CustomersCompanion.insert(
            name: name,
            phone: phone,
            address: Value(address),
          ),
        );
  }

  Stream<List<Customer>> watchCustomers() {
    return db.select(db.customers).watch();
  }

  // ---------- سفارش تعمیر ----------
  Future<int> addRepairOrder({
    required int customerId,
    int? deviceId,
    required String issueDescription,
    int? estimatedCost,
  }) {
    return db.into(db.repairOrders).insert(
          RepairOrdersCompanion.insert(
            customerId: customerId,
            deviceId: Value(deviceId),
            issueDescription: issueDescription,
            estimatedCost: Value(estimatedCost),
          ),
        );
  }

  Stream<List<RepairOrder>> watchRepairOrders() {
    return db.select(db.repairOrders).watch();
  }

  Future<int> countOrdersByStatus(String status) async {
    final rows = await (db.select(db.repairOrders)
          ..where((t) => t.status.equals(status)))
        .get();
    return rows.length;
  }

  // ---------- دستگاه ----------
  Future<int> addDevice({
    required int customerId,
    required String deviceType,
    String? brand,
    String? model,
  }) {
    return db.into(db.devices).insert(
          DevicesCompanion.insert(
            customerId: customerId,
            deviceType: deviceType,
            brand: Value(brand),
            model: Value(model),
          ),
        );
  }
}
