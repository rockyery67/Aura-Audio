import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    await File('docs/performance.json')
        .writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  },
);
