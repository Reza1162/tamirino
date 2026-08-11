import 'database.dart';
import '../repositories/app_repository.dart';

class DbProvider {
  static final AppDatabase database = AppDatabase();
  static final AppRepository repository = AppRepository(database);
}
