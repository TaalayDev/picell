import 'package:integration_test/integration_test_driver.dart';

Future<void> main() async {
  await integrationDriver(
    responseDataCallback: (data) async {
      await writeResponseData(
        data,
        testOutputFilename: 'theme_background_perf',
      );
    },
  );
}
