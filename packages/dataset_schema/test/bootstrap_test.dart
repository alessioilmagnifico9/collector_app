import 'package:flutter_test/flutter_test.dart';
import 'package:dataset_schema/dataset_schema.dart';

void main() {
  test('shared contract loads', () {
    expect(packageSchemaVersion, 1);
  });
}
