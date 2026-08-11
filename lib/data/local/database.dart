import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'database.g.dart';

// ---------- مشتری ----------
class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  TextColumn get address => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ---------- دستگاه ----------
class Devices extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId => integer().references(Customers, #id)();
  TextColumn get deviceType => text()();
  TextColumn get brand => text().nullable()();
  TextColumn get model => text().nullable()();
  TextColumn get serialNumber => text().nullable()();
}

// ---------- سفارش تعمیر ----------
class RepairOrders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId => integer().references(Customers, #id)();
  IntColumn get deviceId => integer().nullable().references(Devices, #id)();
  TextColumn get issueDescription => text()();
  TextColumn get status => text().withDefault(const Constant('registered'))();
  IntColumn get estimatedCost => integer().nullable()();
  IntColumn get deposit => integer().nullable()();
  IntColumn get finalCost => integer().nullable()();
  IntColumn get discount => integer().withDefault(const Constant(0))();
  DateTimeColumn get receivedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deliveredAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get warrantyDays => integer().nullable()();
  TextColumn get signaturePath => text().nullable()();
  TextColumn get estimateStatus => text().withDefault(const Constant('pending'))();
}

// ---------- پرداخت ----------
class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get repairOrderId => integer().references(RepairOrders, #id)();
  IntColumn get amount => integer()();
  DateTimeColumn get paidAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get note => text().nullable()();
}

// ---------- یادآوری ----------
class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get repairOrderId => integer().nullable().references(RepairOrders, #id)();
  TextColumn get title => text()();
  DateTimeColumn get remindAt => dateTime()();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
}

// ---------- کسب‌وکار (تنظیمات) ----------
class BusinessSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get businessName => text()();
  TextColumn get jobType => text()();
  TextColumn get logoPath => text().nullable()();
  BoolColumn get isPro => boolean().withDefault(const Constant(false))();
  DateTimeColumn get proExpiresAt => dateTime().nullable()();
  TextColumn get referralCode => text().nullable()();
  IntColumn get successfulReferrals => integer().withDefault(const Constant(0))();
}

// ---------- قطعات انبار ----------
class Parts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  IntColumn get purchasePrice => integer().withDefault(const Constant(0))();
  IntColumn get sellPrice => integer().withDefault(const Constant(0))();
  IntColumn get lowStockThreshold => integer().withDefault(const Constant(2))();
  TextColumn get barcode => text().nullable()();
}

// ---------- مصرف قطعه در سفارش ----------
class RepairOrderParts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get repairOrderId => integer().references(RepairOrders, #id)();
  IntColumn get partId => integer().references(Parts, #id)();
  IntColumn get quantityUsed => integer().withDefault(const Constant(1))();
}

// ---------- عکس‌های سفارش ----------
class OrderPhotos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get repairOrderId => integer().references(RepairOrders, #id)();
  TextColumn get filePath => text()();
  TextColumn get stage => text()(); // 'before' یا 'after'
  DateTimeColumn get takenAt => dateTime().withDefault(currentDateAndTime)();
}

// ---------- نوبت‌دهی ----------
class Appointments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId => integer().nullable().references(Customers, #id)();
  TextColumn get title => text()();
  DateTimeColumn get appointmentTime => dateTime()();
  TextColumn get note => text().nullable()();
}

@DriftDatabase(tables: [
  Customers,
  Devices,
  RepairOrders,
  Payments,
  Reminders,
  BusinessSettings,
  Parts,
  RepairOrderParts,
  OrderPhotos,
  Appointments,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(parts);
            await m.createTable(repairOrderParts);
          }
          if (from < 3) {
            await m.addColumn(businessSettings, businessSettings.logoPath);
          }
          if (from < 4) {
            await m.addColumn(businessSettings, businessSettings.isPro);
            await m.addColumn(businessSettings, businessSettings.proExpiresAt);
          }
          if (from < 5) {
            await m.addColumn(businessSettings, businessSettings.referralCode);
            await m.addColumn(businessSettings, businessSettings.successfulReferrals);
          }
          if (from < 6) {
            await m.createTable(orderPhotos);
          }
          if (from < 7) {
            await m.addColumn(repairOrders, repairOrders.warrantyDays);
          }
          if (from < 8) {
            await m.addColumn(repairOrders, repairOrders.signaturePath);
          }
          if (from < 9) {
            await m.addColumn(parts, parts.barcode);
          }
          if (from < 10) {
            await m.addColumn(repairOrders, repairOrders.estimateStatus);
          }
          if (from < 11) {
            await m.createTable(appointments);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'tamirino.sqlite'));
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    return NativeDatabase.createInBackground(file);
  });
}
