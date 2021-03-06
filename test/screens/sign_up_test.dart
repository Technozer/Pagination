import 'package:flutter/material.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formz/formz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_idiomatic/import.dart';

class MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

class MockSignUpCubit extends MockCubit<SignUpState> implements SignUpCubit {}

// ignore: avoid_implementing_value_types
class MockEmailInputModel extends Mock implements EmailInputModel {}

// ignore: avoid_implementing_value_types
class MockPasswordInputModel extends Mock implements PasswordInputModel {}

class MockConfirmedPasswordInputModel extends Mock
    implements
        // ignore: avoid_implementing_value_types
        ConfirmedPasswordInputModel {}

void main() {
  group('SignUpScreen', () {
    test('has a route', () {
      expect(SignUpScreen().getRoute(), isA<Route>());
    });

    testWidgets('renders a SignUpForm', (tester) async {
      await tester.pumpWidget(
        RepositoryProvider<AuthenticationRepository>(
          create: (_) => MockAuthenticationRepository(),
          child: MaterialApp(home: SignUpScreen()),
        ),
      );
      expect(find.byType(SignUpForm), findsOneWidget);
    });
  });

  group('SignUpForm', () {
    const testEmail = 'test@gmail.com';
    const testPassword = 'testP@ssw0rd1';
    const testConfirmedPassword = 'testP@ssw0rd1';

    late SignUpCubit signUpCubit;

    setUp(() {
      signUpCubit = MockSignUpCubit();
      when(() => signUpCubit.state).thenReturn(SignUpState());
      when(() => signUpCubit.signUpFormSubmitted()).thenAnswer((_) async {});
    });

    group('calls', () {
      testWidgets('doEmailChanged when email changes', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider.value(
                value: signUpCubit,
                child: SignUpForm(),
              ),
            ),
          ),
        );
        await tester.enterText(find.byKey(Key('_EmailInput')), testEmail);
        verify(() => signUpCubit.doEmailChanged(testEmail)).called(1);
      });

      testWidgets('doPasswordChanged when password changes', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider.value(
                value: signUpCubit,
                child: SignUpForm(),
              ),
            ),
          ),
        );
        await tester.enterText(find.byKey(Key('_PasswordInput')), testPassword);
        verify(() => signUpCubit.doPasswordChanged(testPassword)).called(1);
      });

      testWidgets('doConfirmedPasswordChanged when confirmedPassword changes',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider.value(
                value: signUpCubit,
                child: SignUpForm(),
              ),
            ),
          ),
        );
        await tester.enterText(
          find.byKey(Key('_ConfirmPasswordInput')),
          testConfirmedPassword,
        );
        verify(
          () => signUpCubit.doConfirmedPasswordChanged(testConfirmedPassword),
        ).called(1);
      });

      testWidgets('signUpFormSubmitted when sign up button is pressed',
          (tester) async {
        when(() => signUpCubit.state).thenReturn(
          SignUpState(status: FormzStatus.valid),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider.value(
                value: signUpCubit,
                child: SignUpForm(),
              ),
            ),
          ),
        );
        await tester.tap(find.byKey(Key('_SignUpButton')));
        verify(() => signUpCubit.signUpFormSubmitted()).called(1);
      });
    });

    group('renders', () {
      testWidgets('Sign Up Failure SnackBar when submission fails',
          (tester) async {
        whenListen(
          signUpCubit,
          Stream.fromIterable(<SignUpState>[
            SignUpState(status: FormzStatus.submissionInProgress),
            SignUpState(status: FormzStatus.submissionFailure),
          ]),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider.value(
                value: signUpCubit,
                child: SignUpForm(),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('Sign Up Failure'), findsOneWidget);
      });

      testWidgets('invalid email error text when email is invalid',
          (tester) async {
        final emailInput = MockEmailInputModel();
        when(() => emailInput.invalid).thenReturn(true);
        when(() => signUpCubit.state)
            .thenReturn(SignUpState(emailInput: emailInput));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider.value(
                value: signUpCubit,
                child: SignUpForm(),
              ),
            ),
          ),
        );
        expect(find.text('invalid email'), findsOneWidget);
      });

      testWidgets('invalid password error text when password is invalid',
          (tester) async {
        final passwordInput = MockPasswordInputModel();
        when(() => passwordInput.invalid).thenReturn(true);
        when(() => signUpCubit.state)
            .thenReturn(SignUpState(passwordInput: passwordInput));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider.value(
                value: signUpCubit,
                child: SignUpForm(),
              ),
            ),
          ),
        );
        expect(find.text('invalid password'), findsOneWidget);
      });

      testWidgets(
          'invalid confirmedPassword error text'
          ' when confirmedPassword is invalid', (tester) async {
        final confirmedPasswordInput = MockConfirmedPasswordInputModel();
        when(() => confirmedPasswordInput.invalid).thenReturn(true);
        when(() => signUpCubit.state).thenReturn(
            SignUpState(confirmedPasswordInput: confirmedPasswordInput));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider.value(
                value: signUpCubit,
                child: SignUpForm(),
              ),
            ),
          ),
        );
        expect(find.text('passwords do not match'), findsOneWidget);
      });

      testWidgets('disabled sign up button when status is not validated',
          (tester) async {
        when(() => signUpCubit.state).thenReturn(
          SignUpState(status: FormzStatus.invalid),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider.value(
                value: signUpCubit,
                child: SignUpForm(),
              ),
            ),
          ),
        );
        final signUpButton = tester.widget<RaisedButton>(
          find.byKey(Key('_SignUpButton')),
        );
        expect(signUpButton.enabled, isFalse);
      });

      testWidgets('enabled sign up button when status is validated',
          (tester) async {
        when(() => signUpCubit.state).thenReturn(
          SignUpState(status: FormzStatus.valid),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider.value(
                value: signUpCubit,
                child: SignUpForm(),
              ),
            ),
          ),
        );
        final signUpButton = tester.widget<RaisedButton>(
          find.byKey(Key('_SignUpButton')),
        );
        expect(signUpButton.enabled, isTrue);
      });
    });

    group('navigates', () {
      testWidgets('back to previous page when submission status is success',
          (tester) async {
        whenListen(
          signUpCubit,
          Stream.fromIterable(const <SignUpState>[
            SignUpState(status: FormzStatus.submissionInProgress),
            SignUpState(status: FormzStatus.submissionSuccess),
          ]),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BlocProvider.value(
                value: signUpCubit,
                child: SignUpForm(),
              ),
            ),
          ),
        );
        expect(find.byType(SignUpForm), findsOneWidget);
        await tester.pumpAndSettle();
        expect(find.byType(SignUpForm), findsNothing);
      });
    });
  });
}
