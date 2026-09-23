import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:smart_todo/core/theme/app_theme.dart';
import 'package:smart_todo/presentation/providers/auth_provider.dart';
import 'package:smart_todo/presentation/screens/auth/sign_in_screen.dart';

import '../helpers/fakes.dart';

void main() {
  late MockAuthService service;
  late AuthProvider authProvider;

  setUp(() {
    service = MockAuthService();
    final stateChanges = Stream.value(null);
    when(service.authStateChanges).thenAnswer((_) => stateChanges);
    authProvider = AuthProvider(service);
  });

  Widget harness() {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: MaterialApp(theme: AppTheme.light, home: const SignInScreen()),
    );
  }

  Future<void> tapSignIn(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
    await tester.pump();
  }

  testWidgets('blocks submission and reports both missing fields', (
    tester,
  ) async {
    await tester.pumpWidget(harness());

    await tapSignIn(tester);

    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
    verifyNever(
      () => service.signIn(email: any(named: 'email'), password: any(named: 'password')),
    );
  });

  testWidgets('reports a malformed email address', (tester) async {
    await tester.pumpWidget(harness());

    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.enterText(find.byType(TextFormField).last, 'secret123');
    await tapSignIn(tester);

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Password is required.'), findsNothing);
    verifyNever(
      () => service.signIn(email: any(named: 'email'), password: any(named: 'password')),
    );
  });

  testWidgets('signs in with the typed credentials', (tester) async {
    when(
      () => service.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(harness());

    await tester.enterText(find.byType(TextFormField).first, 'user@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'secret123');
    await tapSignIn(tester);
    await tester.pumpAndSettle();

    verify(
      () => service.signIn(
        email: 'user@example.com',
        password: 'secret123',
      ),
    ).called(1);
  });

  testWidgets('shows the service error inline instead of failing silently', (
    tester,
  ) async {
    when(
      () => service.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(Exception('network down'));

    await tester.pumpWidget(harness());

    await tester.enterText(find.byType(TextFormField).first, 'user@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'secret123');
    await tapSignIn(tester);
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
  });

  testWidgets('leaves the form enabled once a failed attempt settles', (
    tester,
  ) async {
    // A spinner stuck after a failure is the classic version of this bug: the
    // user can never retry.
    when(
      () => service.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(Exception('network down'));

    await tester.pumpWidget(harness());

    await tester.enterText(find.byType(TextFormField).first, 'user@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'secret123');
    await tapSignIn(tester);
    await tester.pumpAndSettle();

    expect(authProvider.isLoading, isFalse);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton).first).onPressed,
      isNotNull,
    );
  });
}
