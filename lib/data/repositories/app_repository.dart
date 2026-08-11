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

  Future<BusinessSetting?> getBusinessSettings() async {
    final rows = await db.select(db.businessSettings).get();
    return rows.isEmpty ? null : rows.first;
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

  Future<void> setFinalCost(int orderId, int finalCost) async {
    await (db.update(db.repairOrders)..where((t) => t.id.equals(orderId)))
        .write(RepairOrdersCompanion(finalCost: Value(finalCost)));
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

  // ---------- پرداخت و بدهی ----------
  Future<void> addPayment({
    required int repairOrderId,
    required int amount,
    String? note,
  }) async {
    await db.into(db.payments).insert(
          PaymentsCompanion.insert(
            repairOrderId: repairOrderId,
            amount: amount,
            note: Value(note),
          ),
        );
  }

  Stream<List<Payment>> watchPaymentsForOrder(int orderId) {
    return (db.select(db.payments)..where((t) => t.repairOrderId.equals(orderId)))
        .watch();
  }

  Future<int> totalPaidForOrder(int orderId) async {
    final rows = await (db.select(db.payments)
          ..where((t) => t.repairOrderId.equals(orderId)))
        .get();
    return rows.fold<int>(0, (sum, p) => sum + p.amount);
  }

  /// مجموع بدهی همه مشتری‌ها (هزینه نهایی یا برآوردی منهای پرداختی‌ها)
  Future<int> totalDebt() async {
    final orders = await db.select(db.repairOrders).get();
    int debt = 0;
    for (final o in orders) {
      final cost = o.finalCost ?? o.estimatedCost ?? 0;
      final paidRows = await (db.select(db.payments)
            ..where((t) => t.repairOrderId.equals(o.id)))
          .get();
      final paid = paidRows.fold<int>(0, (s, p) => s + p.amount);
      final remaining = cost - paid - o.discount;
      if (remaining > 0) debt += remaining;
    }
    return debt;
  }

  Future<int> todayIncome() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final payments = await db.select(db.payments).get();
    return payments
        .where((p) => p.paidAt.isAfter(start))
        .fold<int>(0, (sum, p) => sum + p.amount);
  }
}
