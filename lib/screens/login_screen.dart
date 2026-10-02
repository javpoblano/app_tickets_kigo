import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ed_operador/domain/credential_validator.dart';
import 'package:ed_operador/state/login_controller.dart';
import 'package:ed_operador/state/login_state.dart';

/// The Login_Screen where an Operator enters credentials to authenticate.
///
/// Renders a username field (1–254 characters), an obscured password field
/// (1–128 characters), and a login action wired to [loginControllerProvider].
/// The login action is disabled while submitting; per-field validation and
/// error messages are shown based on the current [LoginState]; the entered
/// username is retained across error states via the field's controller; and
/// the screen applies Material 3 (Requirements 2.1, 2.2, 2.6, 2.7, 2.8, 2.9,
/// 2.10, 2.11).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    // The username field controller retains its text across error states, so
    // there is no need to clear it here (Requirement 2.6).
    ref
        .read(loginControllerProvider.notifier)
        .submit(_usernameController.text, _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    // Navigate on success outside of build to avoid navigating during a build
    // (Requirement 2.6).
    ref.listen<LoginState>(loginControllerProvider, (previous, next) {
      if (next is LoginSuccess) {
        context.go('/main');
      }
    });

    final loginState = ref.watch(loginControllerProvider);
    final isSubmitting = loginState is LoginSubmitting;

    // Resolve per-field validation messages (Requirement 2.10).
    String? usernameError;
    String? passwordError;
    if (loginState is LoginInvalidFields) {
      final result = loginState.result;
      if (result.usernameMissing) {
        usernameError = 'Username is required';
      } else if (result.usernameTooLong) {
        usernameError =
            'Username must be at most ${CredentialValidator.usernameMax} characters';
      }
      if (result.passwordMissing) {
        passwordError = 'Password is required';
      } else if (result.passwordTooLong) {
        passwordError =
            'Password must be at most ${CredentialValidator.passwordMax} characters';
      }
    }

    // Resolve a form-level error banner for credential/auth failures
    // (Requirements 2.8, 2.9).
    String? formError;
    if (loginState is LoginInvalidCredentials) {
      formError = 'Invalid credentials. Please try again.';
    } else if (loginState is LoginError) {
      formError = 'Authentication could not be completed. Please try again.';
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('ED-Operador')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset(
                    'assets/logo.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Sign in',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (formError != null) ...[
                  _ErrorBanner(message: formError),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _usernameController,
                  enabled: !isSubmitting,
                  maxLength: CredentialValidator.usernameMax,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: const OutlineInputBorder(),
                    errorText: usernameError,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  enabled: !isSubmitting,
                  obscureText: true,
                  maxLength: CredentialValidator.passwordMax,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => isSubmitting ? null : _submit(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    errorText: passwordError,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: isSubmitting ? null : _submit,
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Log in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A Material 3 error banner used to surface credential/authentication failures.
class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
