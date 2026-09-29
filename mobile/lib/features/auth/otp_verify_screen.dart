import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import 'auth_repository.dart';

class OtpVerifyScreen extends StatefulWidget {
  const OtpVerifyScreen({
    required this.authRepository,
    required this.phoneNumber,
    required this.onSignedIn,
    this.developmentCode,
    super.key,
  });

  final AuthRepository authRepository;
  final String phoneNumber;
  final VoidCallback onSignedIn;
  final String? developmentCode;

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _codeController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    final developmentCode = widget.developmentCode;

    if (developmentCode != null) {
      _codeController.text = developmentCode;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      setState(() {
        _error = 'Enter the verification code.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.authRepository.verifyOtp(
        phoneNumber: widget.phoneNumber,
        code: code,
      );

      if (!mounted) {
        return;
      }

      widget.onSignedIn();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Verify your number',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text('We sent a code to ${widget.phoneNumber}.'),
                  if (widget.developmentCode != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Development code: ${widget.developmentCode}',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Verification code',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    onSubmitted: (_) {
                      if (!_loading) {
                        _verify();
                      }
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loading ? null : _verify,
                    child: _loading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Verify and continue'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
