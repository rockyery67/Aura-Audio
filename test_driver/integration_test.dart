import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    writeResponseOnFailure: true,
    responseDataCallback: (data) async {
      File('docs/integration-result.txt').writeAsStringSync(
        'screenshots=${(data?['screenshots'] as List?)?.length ?? 0}',
      );
    },
    onScreenshot: (name, bytes, [args]) async {
      final directory = Directory('docs/screenshots')
        ..createSync(recursive: true);
      await File('${directory.path}/$name.png').writeAsBytes(bytes);
      return true;
    },
  );
}
