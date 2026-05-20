import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hiraal_chronic_care/core/config/env_config.dart';
import 'package:hiraal_chronic_care/providers/app_provider.dart';
import 'package:hiraal_chronic_care/screens/auth/splash_screen.dart';
import 'package:provider/provider.dart';

class _TestAppProvider extends AppProvider {
  @override
  Future<bool> tryRestoreSession() async => false;
}

void main() {
  test('EnvConfig builds ERPNext method URLs predictably', () {
    expect(
      EnvConfig.methodUrl('test.method'),
      '${EnvConfig.baseUrl}${EnvConfig.apiPrefix}/test.method',
    );
    expect(
      EnvConfig.methodUrl('/test.method'),
      '${EnvConfig.baseUrl}${EnvConfig.apiPrefix}/test.method',
    );
  });

  testWidgets('Splash screen smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppProvider>(
        create: (_) => _TestAppProvider(),
        child: MaterialApp(
          home: SplashScreen(onGetStarted: () {}),
        ),
      ),
    );

    // Splash shows a loading state, then transitions to the welcome view
    // after tryRestoreSession() resolves and the entrance animation finishes.
    // The screen has repeating animations (pulse, heartbeat) so we cannot
    // pumpAndSettle — pump fixed durations to advance through the transition.
    await tester.pump(); // initial build
    await tester.pump(const Duration(milliseconds: 200)); // async session restore
    await tester.pump(const Duration(milliseconds: 1000)); // entrance complete
    await tester.pump(const Duration(milliseconds: 400)); // AnimatedSwitcher fade
    await tester.pump(const Duration(milliseconds: 600)); // welcome controller

    expect(find.text('Get Started'), findsOneWidget);
  });
}
