import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/routing/app_router.dart';
import '../providers/auth_state_provider.dart';
import '../../../profile/presentation/providers/workspace_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(_emailController.text.trim(), _passwordController.text);
      invalidateWorkspaceData(ref);

      if (!mounted) {
        return;
      }

      context.goNamed(AppRoute.workspace.nameValue);
    } on AuthException catch (error) {
      setState(() {
        _errorMessage = _friendlyMessage(error);
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Unable to sign in right now. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _signOutCurrentSession() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).signOut();
      invalidateWorkspaceData(ref);
      setState(() {
        _infoMessage = 'Signed out. You can log in with another account now.';
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Unable to sign out right now. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final String email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Enter your email address to reset your password.';
        _infoMessage = null;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).resetPassword(email);
      setState(() {
        _infoMessage =
            'Password reset instructions have been sent to your email.';
      });
    } on AuthException catch (error) {
      setState(() {
        _errorMessage = _friendlyMessage(error);
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Unable to start password reset right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _friendlyMessage(AuthException error) {
    if (error.message.toLowerCase().contains('invalid login credentials')) {
      return 'Your email or password is incorrect.';
    }

    return error.message;
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<User?> authState = ref.watch(authStateProvider);
    final User? currentUser = authState.asData?.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Sign in to Tadester Ops',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Admins land in the operations dashboard. Workers land in their assigned jobs view.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (currentUser != null) ...<Widget>[
                      const SizedBox(height: 20),
                      Card(
                        color: const Color(0xFFFFF4F4),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text('Current session detected'),
                              const SizedBox(height: 8),
                              Text(currentUser.email ?? 'Unknown account'),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _isSubmitting ? null : _signOutCurrentSession,
                                icon: const Icon(Icons.logout),
                                label: const Text('Sign out first'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'you@company.com',
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required.';
                        }

                        if (!value.contains('@')) {
                          return 'Enter a valid email address.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    if (_infoMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _infoMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Log in'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isSubmitting ? null : _resetPassword,
                      child: const Text('Forgot Password?'),
                    ),
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => context.goNamed(AppRoute.signUp.nameValue),
                      child: const Text('Create an account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
