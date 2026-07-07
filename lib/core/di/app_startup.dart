import 'package:coffee_app/core/di/service_locator.dart';

Future<void> appStartup() async {
  await initServiceLocator();
}
