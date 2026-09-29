import 'package:flutter/material.dart';

import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/otp_login_screen.dart';
import 'features/home/home_screen.dart';

class OwadanApp extends StatefulWidget {
  const OwadanApp({super.key});
  @override
  State<OwadanApp> createState() => _OwadanAppState();
}

class _OwadanAppState extends State<OwadanApp> {
  late final TokenStorage _storage;
  late final AuthRepository _auth;
  bool _loading = true;
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    _storage = const TokenStorage();
    _auth = AuthRepository(ApiClient(_storage), _storage);
    _restore();
  }

  Future<void> _restore() async {
    final token = await _storage.readRefreshToken();
    if (!mounted) return;
    setState(() {
      _authenticated = token != null && token.isNotEmpty;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Owadan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: _loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _authenticated
          ? HomeScreen(
              authRepository: _auth,
              onSignedOut: () => setState(() => _authenticated = false),
            )
          : OtpLoginScreen(
              authRepository: _auth,
              onSignedIn: () => setState(() => _authenticated = true),
            ),
    );
  }
}
