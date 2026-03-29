import 'package:flutter_test/flutter_test.dart';

import 'package:sathi/src/app/sathi_app.dart';
import 'package:sathi/src/screens/home_screen.dart';
import 'package:sathi/src/services/connectivity_service.dart';
import 'package:sathi/src/services/demo_repository.dart';
import 'package:sathi/src/state/app_state.dart';

void main() {
  testWidgets('home screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      SathiApp(
        appState: AppState(
          repository: DemoRepository(),
          connectivityService: ConnectivityService(useFirebase: false),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
