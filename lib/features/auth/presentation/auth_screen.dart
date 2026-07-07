import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        ref.read(authControllerProvider.notifier).clearMessages();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
            '\u062d\u0633\u0627\u0628 \u0627\u0644\u0645\u0633\u062a\u062e\u062f\u0645'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black87,
          unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white70
              : Colors.black54,
          tabs: const [
            Tab(
                text:
                    '\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644'),
            Tab(
                text:
                    '\u0625\u0646\u0634\u0627\u0621 \u062d\u0633\u0627\u0628'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (state.errorMessage != null &&
              state.errorMessage!.trim().isNotEmpty)
            _MessageBanner(
              text: state.errorMessage!,
              isError: true,
            ),
          if (state.message != null && state.message!.trim().isNotEmpty)
            _MessageBanner(
              text: state.message!,
              isError: false,
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _LoginForm(),
                _RegisterForm(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.text, required this.isError});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isError
            ? Theme.of(context).colorScheme.error.withOpacity(0.12)
            : Colors.green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isError
              ? Theme.of(context).colorScheme.error
              : Colors.green.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LoginForm extends ConsumerStatefulWidget {
  const _LoginForm();

  @override
  ConsumerState<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText:
                      '\u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a',
                  border: const OutlineInputBorder(),
                  errorText: state.fieldErrors['email'],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '\u064a\u0631\u062c\u0649 \u0625\u062f\u062e\u0627\u0644 \u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a.';
                  }
                  if (!value.contains('@')) {
                    return '\u0635\u064a\u063a\u0629 \u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a \u063a\u064a\u0631 \u0635\u062d\u064a\u062d\u0629.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText:
                      '\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631',
                  border: const OutlineInputBorder(),
                  errorText: state.fieldErrors['password'],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '\u064a\u0631\u062c\u0649 \u0625\u062f\u062e\u0627\u0644 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ElevatedButton(
          onPressed: state.isLoading
              ? null
              : () async {
                  FocusScope.of(context).unfocus();
                  if (!_formKey.currentState!.validate()) return;

                  final success =
                      await ref.read(authControllerProvider.notifier).login(
                            email: _emailController.text.trim(),
                            password: _passwordController.text,
                          );
                  if (!mounted) return;
                  if (success) Navigator.of(context).pop();
                },
          child: state.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  '\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062f\u062e\u0648\u0644'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: state.isLoading
              ? null
              : () async {
                  FocusScope.of(context).unfocus();
                  final success = await ref
                      .read(authControllerProvider.notifier)
                      .loginWithGoogle();
                  if (!mounted) return;
                  if (success) Navigator.of(context).pop();
                },
          icon: const _GoogleBrandMark(),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                  '\u0645\u062a\u0627\u0628\u0639\u0629 \u0628\u0627\u0633\u062a\u062e\u062f\u0627\u0645 '),
              _GoogleBrandWord(),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (Platform.isIOS) ...[
          OutlinedButton.icon(
            onPressed: state.isLoading
                ? null
                : () async {
                    FocusScope.of(context).unfocus();
                    final success = await ref
                        .read(authControllerProvider.notifier)
                        .loginWithApple();
                    if (!mounted) return;
                    if (success) Navigator.of(context).pop();
                  },
            icon: const Icon(Icons.apple),
            label: const Text(
              '\u0645\u062a\u0627\u0628\u0639\u0629 \u0628\u0627\u0633\u062a\u062e\u062f\u0627\u0645 Apple',
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
              '\u0627\u0644\u0645\u062a\u0627\u0628\u0639\u0629 \u0643\u0636\u064a\u0641'),
        ),
      ],
    );
  }
}

class _GoogleBrandMark extends StatelessWidget {
  const _GoogleBrandMark();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        color: Color(0xFF4285F4),
        fontSize: 22,
        fontWeight: FontWeight.w900,
        height: 1,
      ),
    );
  }
}

class _GoogleBrandWord extends StatelessWidget {
  const _GoogleBrandWord();

  @override
  Widget build(BuildContext context) {
    return const Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'G',
            style: TextStyle(
              color: Color(0xFF4285F4),
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: 'o', style: TextStyle(color: Color(0xFFEA4335))),
          TextSpan(text: 'o', style: TextStyle(color: Color(0xFFFBBC05))),
          TextSpan(text: 'g', style: TextStyle(color: Color(0xFF4285F4))),
          TextSpan(text: 'l', style: TextStyle(color: Color(0xFF34A853))),
          TextSpan(text: 'e', style: TextStyle(color: Color(0xFFEA4335))),
        ],
      ),
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _RegisterForm extends ConsumerStatefulWidget {
  const _RegisterForm();

  @override
  ConsumerState<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText:
                      '\u0627\u0644\u0627\u0633\u0645 \u0627\u0644\u0643\u0627\u0645\u0644',
                  border: const OutlineInputBorder(),
                  errorText: state.fieldErrors['name'],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '\u064a\u0631\u062c\u0649 \u0625\u062f\u062e\u0627\u0644 \u0627\u0644\u0627\u0633\u0645.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText:
                      '\u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a',
                  border: const OutlineInputBorder(),
                  errorText: state.fieldErrors['email'],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '\u064a\u0631\u062c\u0649 \u0625\u062f\u062e\u0627\u0644 \u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a.';
                  }
                  if (!value.contains('@')) {
                    return '\u0635\u064a\u063a\u0629 \u0627\u0644\u0628\u0631\u064a\u062f \u0627\u0644\u0625\u0644\u0643\u062a\u0631\u0648\u0646\u064a \u063a\u064a\u0631 \u0635\u062d\u064a\u062d\u0629.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText:
                      '\u0631\u0642\u0645 \u0627\u0644\u0647\u0627\u062a\u0641 (\u0627\u062e\u062a\u064a\u0627\u0631\u064a)',
                  border: const OutlineInputBorder(),
                  errorText: state.fieldErrors['phone'],
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText:
                      '\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631',
                  border: const OutlineInputBorder(),
                  errorText: state.fieldErrors['password'],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '\u064a\u0631\u062c\u0649 \u0625\u062f\u062e\u0627\u0644 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631.';
                  }
                  if (value.length < 8) {
                    return '\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 \u064a\u062c\u0628 \u0623\u0646 \u062a\u0643\u0648\u0646 8 \u0623\u062d\u0631\u0641 \u0639\u0644\u0649 \u0627\u0644\u0623\u0642\u0644.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText:
                      '\u062a\u0623\u0643\u064a\u062f \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631',
                  border: const OutlineInputBorder(),
                  errorText: state.fieldErrors['password_confirmation'],
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return '\u062a\u0623\u0643\u064a\u062f \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 \u063a\u064a\u0631 \u0645\u0637\u0627\u0628\u0642.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ElevatedButton(
          onPressed: state.isLoading
              ? null
              : () async {
                  FocusScope.of(context).unfocus();
                  if (!_formKey.currentState!.validate()) return;

                  final success = await ref
                      .read(authControllerProvider.notifier)
                      .register(
                        name: _nameController.text.trim(),
                        email: _emailController.text.trim(),
                        phone: _phoneController.text.trim().isEmpty
                            ? null
                            : _phoneController.text.trim(),
                        password: _passwordController.text,
                        passwordConfirmation: _confirmPasswordController.text,
                      );
                  if (!mounted) return;
                  if (success) Navigator.of(context).pop();
                },
          child: state.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  '\u0625\u0646\u0634\u0627\u0621 \u0627\u0644\u062d\u0633\u0627\u0628'),
        ),
      ],
    );
  }
}
