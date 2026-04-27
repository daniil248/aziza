// Default entry point — delegates to the client app.
// Run a specific app via:
//   flutter run -t lib/main_client.dart
//   flutter run -t lib/main_courier.dart
//   flutter run -t lib/main_admin.dart
import 'main_client.dart' as client;

void main() => client.main();
