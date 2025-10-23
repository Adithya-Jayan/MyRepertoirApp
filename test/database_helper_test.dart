import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:repertoire/database/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  test('database opens and creates tables', () async {
    final helper = DatabaseHelper.instance;
    final db = await helper.database;
    expect(db.isOpen, isTrue);
    await db.close();
  });
}
