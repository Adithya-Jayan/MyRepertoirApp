import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:repertoire/database/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock path_provider plugin
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return '.'; // Return current directory for testing
      }
      return null;
    },
  );

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('database opens and creates tables', () async {
    final helper = DatabaseHelper.instance;
    final db = await helper.database;
    expect(db.isOpen, isTrue);
    await db.close();
  });
}
