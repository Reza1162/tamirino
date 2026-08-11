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
}

// ---------- قطعات انبار ----------
class Parts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  IntColumn get purchasePrice => integer().withDefault(const Constant(0))();
  IntColumn get sellPrice => integer().withDefault(const Constant(0))();
  IntColumn get lowStockThreshold => integer().withDefault(const Constant(2))();
}

// ---------- مصرف قطعه در سفارش ----------
class RepairOrderParts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get repairOrderId => integer().references(RepairOrders, #id)();
  IntColumn get partId => integer().references(Parts, #id)();
  IntColumn get quantityUsed => integer().withDefault(const Constant(1))();
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
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(parts);
            await m.createTable(repairOrderParts);
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
