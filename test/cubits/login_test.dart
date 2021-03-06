import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formz/formz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_idiomatic/import.dart';

class MockAuthenticationRepository extends Mock
    implements AuthenticationRepository {}

void main() {
  group('LoginState', () {
    const emailInput = EmailInputModel.dirty('email');
    const passwordInput = PasswordInputModel.dirty('password');

    test('supports value comparisons', () {
      expect(LoginState(), LoginState());
    });

    test('returns same object when no properties are passed', () {
      expect(LoginState().copyWith(), LoginState());
    });

    test('returns object with updated status when status is passed', () {
      expect(
        LoginState().copyWith(status: FormzStatus.pure),
        LoginState(),
      );
    });

    test('returns object with updated email when email is passed', () {
      expect(
        LoginState().copyWith(emailInput: emailInput),
        LoginState(emailInput: emailInput),
      );
    });

    test('returns object with updated password when password is passed', () {
      expect(
        LoginState().copyWith(passwordInput: passwordInput),
        LoginState(passwordInput: passwordInput),
      );
    });
  });

  group('LoginCubit', () {
    const invalidEmailString = 'invalid';
    const invalidEmail = EmailInputModel.dirty(invalidEmailString);

    const validEmailString = 'test@gmail.com';
    const validEmail = EmailInputModel.dirty(validEmailString);

    const invalidPasswordString = 'invalid';
    const invalidPassword = PasswordInputModel.dirty(invalidPasswordString);

    const validPasswordString = 't0pS3cret1234';
    const validPassword = PasswordInputModel.dirty(validPasswordString);

    late AuthenticationRepository authenticationRepository;

    setUp(() {
      authenticationRepository = MockAuthenticationRepository();
      when(
        () => authenticationRepository.logInWithGoogle(),
      ).thenAnswer((_) async {});
      when(
        () => authenticationRepository.logInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});
    });

    test('initial state is LoginState', () async {
      final loginCubit = LoginCubit(authenticationRepository);
      expect(loginCubit.state, LoginState());
      await loginCubit.close();
    });

    group('doEmailChanged', () {
      blocTest<LoginCubit, LoginState>(
        'emits [invalid] when email/password are invalid',
        build: () => LoginCubit(authenticationRepository),
        act: (cubit) => cubit.doEmailChanged(invalidEmailString),
        expect: () => <LoginState>[
          LoginState(emailInput: invalidEmail, status: FormzStatus.invalid),
        ],
      );

      blocTest<LoginCubit, LoginState>(
        'emits [valid] when email/password are valid',
        build: () => LoginCubit(authenticationRepository),
        seed: () => LoginState(passwordInput: validPassword),
        act: (cubit) => cubit.doEmailChanged(validEmailString),
        expect: () => <LoginState>[
          LoginState(
            emailInput: validEmail,
            passwordInput: validPassword,
            status: FormzStatus.valid,
          ),
        ],
      );
    });

    group('doPasswordChanged', () {
      blocTest<LoginCubit, LoginState>(
        'emits [invalid] when email/password are invalid',
        build: () => LoginCubit(authenticationRepository),
        act: (cubit) => cubit.doPasswordChanged(invalidPasswordString),
        expect: () => <LoginState>[
          LoginState(
            passwordInput: invalidPassword,
            status: FormzStatus.invalid,
          ),
        ],
      );

      blocTest<LoginCubit, LoginState>(
        'emits [valid] when email/password are valid',
        build: () => LoginCubit(authenticationRepository),
        seed: () => LoginState(emailInput: validEmail),
        act: (cubit) => cubit.doPasswordChanged(validPasswordString),
        expect: () => <LoginState>[
          LoginState(
            emailInput: validEmail,
            passwordInput: validPassword,
            status: FormzStatus.valid,
          ),
        ],
      );
    });

    group('logInWithCredentials', () {
      blocTest<LoginCubit, LoginState>(
        'does nothing when status is not validated',
        build: () => LoginCubit(authenticationRepository),
        act: (cubit) => cubit.logInWithCredentials(),
        expect: () => <LoginState>[],
      );

      blocTest<LoginCubit, LoginState>(
        'calls logInWithEmailAndPassword with correct email/password',
        build: () => LoginCubit(authenticationRepository),
        seed: () => LoginState(
          status: FormzStatus.valid,
          emailInput: validEmail,
          passwordInput: validPassword,
        ),
        act: (cubit) => cubit.logInWithCredentials(),
        verify: (_) {
          verify(
            () => authenticationRepository.logInWithEmailAndPassword(
              email: validEmailString,
              password: validPasswordString,
            ),
          ).called(1);
        },
      );

      blocTest<LoginCubit, LoginState>(
        'emits [submissionInProgress, submissionSuccess] '
        'when logInWithEmailAndPassword succeeds',
        build: () => LoginCubit(authenticationRepository),
        seed: () => LoginState(
          status: FormzStatus.valid,
          emailInput: validEmail,
          passwordInput: validPassword,
        ),
        act: (cubit) => cubit.logInWithCredentials(),
        expect: () => <LoginState>[
          LoginState(
            status: FormzStatus.submissionInProgress,
            emailInput: validEmail,
            passwordInput: validPassword,
          ),
          LoginState(
            status: FormzStatus.submissionSuccess,
            emailInput: validEmail,
            passwordInput: validPassword,
          )
        ],
      );

      blocTest<LoginCubit, LoginState>(
        'emits [submissionInProgress, submissionFailure] '
        'when logInWithEmailAndPassword fails',
        setUp: () {
          when(
            () => authenticationRepository.logInWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenThrow(Exception('oops'));
        },
        build: () => LoginCubit(authenticationRepository),
        seed: () => LoginState(
          status: FormzStatus.valid,
          emailInput: validEmail,
          passwordInput: validPassword,
        ),
        act: (cubit) => cubit.logInWithCredentials(),
        expect: () => <LoginState>[
          LoginState(
            status: FormzStatus.submissionInProgress,
            emailInput: validEmail,
            passwordInput: validPassword,
          ),
          LoginState(
            status: FormzStatus.submissionFailure,
            emailInput: validEmail,
            passwordInput: validPassword,
          )
        ],
      );
    });

    group('logInWithGoogle', () {
      blocTest<LoginCubit, LoginState>(
        'calls logInWithGoogle',
        build: () => LoginCubit(authenticationRepository),
        act: (cubit) => cubit.logInWithGoogle(),
        verify: (_) {
          verify(
            () => authenticationRepository.logInWithGoogle(),
          ).called(1);
        },
      );

      blocTest<LoginCubit, LoginState>(
        'emits [submissionInProgress, submissionSuccess] '
        'when logInWithGoogle succeeds',
        build: () => LoginCubit(authenticationRepository),
        act: (cubit) => cubit.logInWithGoogle(),
        expect: () => <LoginState>[
          LoginState(status: FormzStatus.submissionInProgress),
          LoginState(status: FormzStatus.submissionSuccess)
        ],
      );

      blocTest<LoginCubit, LoginState>(
        'emits [submissionInProgress, submissionFailure] '
        'when logInWithGoogle fails',
        setUp: () {
          when(
            () => authenticationRepository.logInWithGoogle(),
          ).thenThrow(Exception('oops'));
        },
        build: () => LoginCubit(authenticationRepository),
        act: (cubit) => cubit.logInWithGoogle(),
        expect: () => <LoginState>[
          LoginState(status: FormzStatus.submissionInProgress),
          LoginState(status: FormzStatus.submissionFailure)
        ],
      );
    });
  });
}
