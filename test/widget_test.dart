import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sathi/src/app/sathi_app.dart';
import 'package:sathi/src/screens/insights_screen.dart';
import 'package:sathi/src/services/demo_repository.dart';
import 'package:sathi/src/state/app_state.dart';

void main() {
  testWidgets('home shows weekly check-in reminder when a week has passed', (tester) async {
    await tester.pumpWidget(
      SathiApp(
        appState: AppState(repository: DemoRepository()),
      ),
    );

    expect(find.text('Time for your weekly check-in'), findsOneWidget);
    expect(find.text("Let's see how you're doing today."), findsOneWidget);
  });

  testWidgets('insights screen shows score visuals and comparison language', (tester) async {
    await tester.pumpWidget(
      SathiApp(
        appState: AppState(repository: DemoRepository()),
      ),
    );

    final context = tester.element(find.text('Sathi'));
    Navigator.of(context).pushNamed(InsightsScreen.routeName);
    await tester.pumpAndSettle();

    expect(find.text('Weekly insight'), findsOneWidget);
    expect(find.text('Theme intensity'), findsOneWidget);
    expect(find.text('Where this week felt heaviest'), findsOneWidget);
    expect(find.text('Compared with last week'), findsOneWidget);
  });
}
