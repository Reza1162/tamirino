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

  Future<void> updateLogo(String logoPath) async {
    final existing = await getBusinessSettings();
    if (existing == null) return;
    await (db.update(db.businessSettings)..where((t) => t.id.equals(existing.id)))
        .write(BusinessSettingsCompanion(logoPath: Value(logoPath)));
  }

  // ---------- اشتراک ----------
  static const int freeCustomerLimit = 30;
  static const int freeOrderLimit = 30;

  Future<bool> isPro() async {
    final settings = await getBusinessSettings();
    if (settings == null) return false;
    if (!settings.isPro) return false;
    if (settings.proExpiresAt != null && settings.proExpiresAt!.isBefore(DateTime.now())) {
      return false;
    }
    return true;
  }

  Future<void> activatePro({required Duration duration}) async {
    final existing = await getBusinessSettings();
    if (existing == null) return;
    await (db.update(db.businessSettings)..where((t) => t.id.equals(existing.id))).write(
      BusinessSettingsCompanion(
        isPro: const Value(true),
        proExpiresAt: Value(DateTime.now().add(duration)),
      ),
    );
  }

  Future<int> customerCount() async {
    final rows = await db.select(db.customers).get();
    return rows.length;
  }

  Future<int> orderCount() async {
    final rows = await db.select(db.repairOrders).get();
    return rows.length;
  }

  /// بررسی اینکه آیا افزودن مشتری جدید مجاز است
  Future<bool> canAddCustomer() async {
    if (await isPro()) return true;
    return (await customerCount()) < freeCustomerLimit;
  }

  /// بررسی اینکه آیا ثبت سفارش جدید مجاز است
  Future<bool> canAddOrder() async {
    if (await isPro()) return true;
    return (await orderCount()) < freeOrderLimit;
  }

  // ---------- دعوت دوستان ----------
  Future<String> getOrCreateReferralCode() async {
    final existing = await getBusinessSettings();
    if (existing == null) return '';
    if (existing.referralCode != null && existing.referralCode!.isNotEmpty) {
      return existing.referralCode!;
    }
    final code = 'TMR${existing.id.toString().padLeft(4, '0')}${DateTime.now().millisecondsSinceEpoch % 1000}';
    await (db.update(db.businessSettings)..where((t) => t.id.equals(existing.id)))
        .write(BusinessSettingsCompanion(referralCode: Value(code)));
    return code;
  }

  Future<int> referralRewardDays() async {
    final settings = await getBusinessSettings();
    return (settings?.successfulReferrals ?? 0) * 7;
  }

  /// وقتی یک دعوت موفق ثبت می‌شود (فعلاً به‌صورت دستی/تستی)
  Future<void> registerSuccessfulReferral() async {
    final existing = await getBusinessSettings();
    if (existing == null) return;
    final newCount = existing.successfulReferrals + 1;
    await (db.update(db.businessSettings)..where((t) => t.id.equals(existing.id)))
        .write(BusinessSettingsCompanion(successfulReferrals: Value(newCount)));

    // پاداش ۷ روز حرفه‌ای رایگان
    final currentExpiry = existing.proExpiresAt ?? DateTime.now();
    final base = currentExpiry.isAfter(DateTime.now()) ? currentExpiry : DateTime.now();
    await (db.update(db.businessSettings)..where((t) => t.id.equals(existing.id))).write(
      BusinessSettingsCompanion(
        isPro: const Value(true),
        proExpiresAt: Value(base.add(const Duration(days: 7))),
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

  Future<void> setFinalCost(int orderId, int finalCost) async {
    await (db.update(db.repairOrders)..where((t) => t.id.equals(orderId)))
        .write(RepairOrdersCompanion(finalCost: Value(finalCost)));
  }

  Future<void> setEstimateStatus(int orderId, String status) async {
    await (db.update(db.repairOrders)..where((t) => t.id.equals(orderId)))
        .write(RepairOrdersCompanion(estimateStatus: Value(status)));
  }

  Future<void> setInternalNote(int orderId, String note) async {
    await (db.update(db.repairOrders)..where((t) => t.id.equals(orderId)))
        .write(RepairOrdersCompanion(notes: Value(note)));
  }

  Future<void> setSignature(int orderId, String signaturePath) async {
    await (db.update(db.repairOrders)..where((t) => t.id.equals(orderId)))
        .write(RepairOrdersCompanion(signaturePath: Value(signaturePath)));
  }

  Future<void> setWarranty(int orderId, int warrantyDays) async {
    await (db.update(db.repairOrders)..where((t) => t.id.equals(orderId))).write(
      RepairOrdersCompanion(
        warrantyDays: Value(warrantyDays),
        deliveredAt: Value(DateTime.now()),
      ),
    );
  }

  /// وضعیت گارانتی: null یعنی گارانتی ثبت نشده
  static bool? isUnderWarranty(RepairOrder order) {
    if (order.warrantyDays == null || order.deliveredAt == null) return null;
    final expiry = order.deliveredAt!.add(Duration(days: order.warrantyDays!));
    return DateTime.now().isBefore(expiry);
  }

  static DateTime? warrantyExpiryDate(RepairOrder order) {
    if (order.warrantyDays == null || order.deliveredAt == null) return null;
    return order.deliveredAt!.add(Duration(days: order.warrantyDays!));
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
    String? serialNumber,
  }) {
    return db.into(db.devices).insert(
          DevicesCompanion.insert(
            customerId: customerId,
            deviceType: deviceType,
            brand: Value(brand),
            model: Value(model),
            serialNumber: Value(serialNumber),
          ),
        );
  }

  Stream<List<Device>> watchDevicesForCustomer(int customerId) {
    return (db.select(db.devices)..where((t) => t.customerId.equals(customerId))).watch();
  }

  Future<Device?> getDevice(int id) {
    return (db.select(db.devices)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<List<RepairOrder>> watchOrdersForDevice(int deviceId) {
    return (db.select(db.repairOrders)..where((t) => t.deviceId.equals(deviceId))).watch();
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

// ---------- انبار قطعات ----------
  Future<int> addPart({
    required String name,
    required int quantity,
    required int purchasePrice,
    required int sellPrice,
  }) async {
    final id = await db.into(db.parts).insert(
          PartsCompanion.insert(
            name: name,
            quantity: Value(quantity),
            purchasePrice: Value(purchasePrice),
            sellPrice: Value(sellPrice),
          ),
        );
    final code = 'TMR-P${id.toString().padLeft(5, '0')}';
    await (db.update(db.parts)..where((t) => t.id.equals(id)))
        .write(PartsCompanion(barcode: Value(code)));
    return id;
  }

  Stream<List<Part>> watchParts() => db.select(db.parts).watch();

  Future<void> adjustPartQuantity(int partId, int delta) async {
    final part = await (db.select(db.parts)..where((t) => t.id.equals(partId))).getSingle();
    final newQty = (part.quantity + delta).clamp(0, 1 << 30);
    await (db.update(db.parts)..where((t) => t.id.equals(partId)))
        .write(PartsCompanion(quantity: Value(newQty)));
  }

  Future<void> usePartInOrder({
    required int repairOrderId,
    required int partId,
    required int quantityUsed,
  }) async {
    await db.into(db.repairOrderParts).insert(
          RepairOrderPartsCompanion.insert(
            repairOrderId: repairOrderId,
            partId: partId,
            quantityUsed: Value(quantityUsed),
          ),
        );
    await adjustPartQuantity(partId, -quantityUsed);
  }

  // ---------- نوبت‌دهی ----------
  Future<int> addAppointment({
    int? customerId,
    required String title,
    required DateTime appointmentTime,
    String? note,
  }) {
    return db.into(db.appointments).insert(
          AppointmentsCompanion.insert(
            customerId: Value(customerId),
            title: title,
            appointmentTime: appointmentTime,
            note: Value(note),
          ),
        );
  }

  Stream<List<Appointment>> watchAppointments() {
    return (db.select(db.appointments)
          ..orderBy([(t) => OrderingTerm(expression: t.appointmentTime)]))
        .watch();
  }

  Future<void> deleteAppointment(int id) async {
    await (db.delete(db.appointments)..where((t) => t.id.equals(id))).go();
  }

  // ---------- عکس‌های سفارش ----------
  Future<void> addOrderPhoto({
    required int repairOrderId,
    required String filePath,
    required String stage,
  }) async {
    await db.into(db.orderPhotos).insert(
          OrderPhotosCompanion.insert(
            repairOrderId: repairOrderId,
            filePath: filePath,
            stage: stage,
          ),
        );
  }

  Stream<List<OrderPhoto>> watchOrderPhotos(int orderId) {
    return (db.select(db.orderPhotos)..where((t) => t.repairOrderId.equals(orderId))).watch();
  }

  Future<void> deleteOrderPhoto(int id) async {
    await (db.delete(db.orderPhotos)..where((t) => t.id.equals(id))).go();
  }

  // ---------- گزارش سود ----------
  Future<Map<String, int>> profitReport() async {
    final orders = await db.select(db.repairOrders).get();
    final delivered = orders.where((o) => o.status == 'delivered').toList();

    int revenue = 0;
    for (final o in delivered) {
      revenue += (o.finalCost ?? o.estimatedCost ?? 0) - o.discount;
    }

    final usedParts = await db.select(db.repairOrderParts).get();
    int partsCost = 0;
    for (final up in usedParts) {
      final part = await (db.select(db.parts)..where((t) => t.id.equals(up.partId))).getSingleOrNull();
      if (part != null) {
        partsCost += part.purchasePrice * up.quantityUsed;
      }
    }

    return {
      'revenue': revenue,
      'partsCost': partsCost,
      'profit': revenue - partsCost,
      'ordersCount': delivered.length,
    };
  }

  // ---------- یادآوری‌ها ----------
  Future<int> addReminder({
    int? repairOrderId,
    required String title,
    required DateTime remindAt,
  }) {
    return db.into(db.reminders).insert(
          RemindersCompanion.insert(
            repairOrderId: Value(repairOrderId),
            title: title,
            remindAt: remindAt,
          ),
        );
  }

  Stream<List<Reminder>> watchReminders() {
    return (db.select(db.reminders)
          ..orderBy([(t) => OrderingTerm(expression: t.remindAt)]))
        .watch();
  }

  Future<void> markReminderDone(int id) async {
    await (db.update(db.reminders)..where((t) => t.id.equals(id)))
        .write(const RemindersCompanion(isDone: Value(true)));
  }

  Future<void> deleteReminder(int id) async {
    await (db.delete(db.reminders)..where((t) => t.id.equals(id))).go();
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
