import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import 'auth_repository.dart';
import 'otp_verify_screen.dart';

class OtpLoginScreen extends StatefulWidget {
  const OtpLoginScreen({
    required this.authRepository,
    required this.onSignedIn,
    super.key,
  });
  final AuthRepository authRepository;
  final VoidCallback onSignedIn;
  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController(text: '+993');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.authRepository.requestOtp(_phone.text.trim());
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OtpVerifyScreen(
            authRepository: widget.authRepository,
            phoneNumber: _phone.text.trim(),
            developmentCode: result.developmentCode,
            onSignedIn: widget.onSignedIn,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  children: [
                    Text(
                      'Owadan',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Beauty services, easier to discover and book.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        hintText: '+99361123456',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (value) =>
                          RegExp(r'^\+[1-9]\d{7,14}$')
                              .hasMatch(value?.trim() ?? '')
                          ? null
                          : 'Use international format.',
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const CircularProgressIndicator()
                          : const Text('Continue'),
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
