import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/services/backend_api_client.dart';
import '../../data/organization_onboarding_repository.dart';
import '../../domain/models/organization_option.dart';
import '../providers/auth_state_provider.dart';
import '../providers/onboarding_providers.dart';

enum _SignUpMode { joinOrganization, createOrganization }

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final TextEditingController _organizationNameController =
      TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  _SignUpMode _mode = _SignUpMode.joinOrganization;
  String? _selectedOrganizationId;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _organizationNameController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_mode == _SignUpMode.joinOrganization &&
        _selectedOrganizationId == null) {
      setState(() {
        _errorMessage = 'Choose your organization before creating an account.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    final OrganizationOnboardingRepository onboardingRepository = ref.read(
      organizationOnboardingRepositoryProvider,
    );
    final authRepository = ref.read(authRepositoryProvider);
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    try {
      if (_mode == _SignUpMode.joinOrganization) {
        await onboardingRepository.signUpForOrganization(
          JoinOrganizationSignUpInput(
            organizationId: _selectedOrganizationId!,
            fullName: _fullNameController.text.trim(),
            email: email,
            password: password,
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
          ),
        );
      } else {
        await onboardingRepository.signUpAsOrganization(
          CreateOrganizationSignUpInput(
            organizationName: _organizationNameController.text.trim(),
            fullName: _fullNameController.text.trim(),
            email: email,
            password: password,
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
          ),
        );
      }

      await authRepository.signIn(email, password);

      if (!mounted) {
        return;
      }

      context.goNamed(AppRoute.workspace.nameValue);
    } on BackendApiException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } on AuthException catch (error) {
      setState(() {
        _errorMessage = _friendlyMessage(error.message);
      });
    } catch (_) {
      setState(() {
        _errorMessage =
            'Unable to create your account right now. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _friendlyMessage(String message) {
    if (message.toLowerCase().contains('already')) {
      return 'An account with that email already exists.';
    }

    return message;
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<OrganizationOption>> organizationsAsync = ref.watch(
      availableOrganizationsProvider,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Create your Tadester Ops account',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _mode == _SignUpMode.joinOrganization
                          ? 'Join an existing organization as a worker account.'
                          : 'Create a new organization and become its first admin.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    SegmentedButton<_SignUpMode>(
                      segments: const <ButtonSegment<_SignUpMode>>[
                        ButtonSegment<_SignUpMode>(
                          value: _SignUpMode.joinOrganization,
                          label: Text('Join organization'),
                          icon: Icon(Icons.badge_outlined),
                        ),
                        ButtonSegment<_SignUpMode>(
                          value: _SignUpMode.createOrganization,
                          label: Text('Create organization'),
                          icon: Icon(Icons.apartment),
                        ),
                      ],
                      selected: <_SignUpMode>{_mode},
                      onSelectionChanged: (Set<_SignUpMode> value) {
                        setState(() {
                          _mode = value.first;
                          _errorMessage = null;
                          _infoMessage = null;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    if (_mode == _SignUpMode.joinOrganization)
                      organizationsAsync.when(
                        data: (List<OrganizationOption> organizations) {
                          return DropdownButtonFormField<String>(
                            initialValue: _selectedOrganizationId,
                            decoration: const InputDecoration(
                              labelText: 'What\'s your organization?',
                            ),
                            items: organizations
                                .map(
                                  (OrganizationOption organization) =>
                                      DropdownMenuItem<String>(
                                        value: organization.id,
                                        child: Text(organization.name),
                                      ),
                                )
                                .toList(growable: false),
                            onChanged: (String? value) {
                              setState(() {
                                _selectedOrganizationId = value;
                              });
                            },
                            validator: (String? value) => value == null
                                ? 'Choose your organization.'
                                : null,
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (Object error, StackTrace stackTrace) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'We could not load organizations: $error',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => ref.invalidate(
                                availableOrganizationsProvider,
                              ),
                              child: const Text('Retry organization list'),
                            ),
                          ],
                        ),
                      )
                    else
                      TextFormField(
                        controller: _organizationNameController,
                        decoration: const InputDecoration(
                          labelText: 'Organization name',
                          hintText: 'Prairie Site Ops',
                        ),
                        validator: (String? value) {
                          if (_mode != _SignUpMode.createOrganization) {
                            return null;
                          }
                          if (value == null || value.trim().isEmpty) {
                            return 'Organization name is required.';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(labelText: 'Full name'),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full name is required.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone (optional)',
                      ),
                    ),
                    const SizedBox(height: 16),
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
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm password',
                      ),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password.';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match.';
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
                          : Text(
                              _mode == _SignUpMode.joinOrganization
                                  ? 'Join organization'
                                  : 'Create organization',
                            ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => context.goNamed(AppRoute.login.nameValue),
                      child: const Text('Already have an account? Log in'),
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
