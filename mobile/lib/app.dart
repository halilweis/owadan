import 'package:flutter/material.dart';

import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/otp_login_screen.dart';
import 'features/booking/booking_repository.dart';
import 'features/discovery/discovery_repository.dart';
import 'features/home/home_screen.dart';
import 'features/profile/profile_repository.dart';

class OwadanApp extends StatefulWidget {
  const OwadanApp({super.key});

  @override
  State<OwadanApp> createState() => _OwadanAppState();
}

class _OwadanAppState extends State<OwadanApp> {
  late final TokenStorage _tokenStorage;
  late final ApiClient _apiClient;
  late final AuthRepository _authRepository;
  late final DiscoveryRepository _discoveryRepository;
  late final BookingRepository _bookingRepository;
  late final ProfileRepository _profileRepository;

  bool _loading = true;
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();

    _tokenStorage = const TokenStorage();
    _apiClient = ApiClient(_tokenStorage);
    _authRepository = AuthRepository(_apiClient, _tokenStorage);
    _discoveryRepository = DiscoveryRepository(_apiClient);
    _bookingRepository = BookingRepository(_apiClient);
    _profileRepository = ProfileRepository(_apiClient);

    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final accessToken = await _tokenStorage.readAccessToken();
    final refreshToken = await _tokenStorage.readRefreshToken();

    if (!mounted) {
      return;
    }

    setState(() {
      _authenticated =
          (accessToken != null && accessToken.isNotEmpty) ||
          (refreshToken != null && refreshToken.isNotEmpty);
      _loading = false;
    });
  }

  void _signedIn() {
    setState(() {
      _authenticated = true;
    });
  }

  void _signedOut() {
    setState(() {
      _authenticated = false;
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
              authRepository: _authRepository,
              discoveryRepository: _discoveryRepository,
              bookingRepository: _bookingRepository,
              profileRepository: _profileRepository,
              onSignedOut: _signedOut,
            )
          : OtpLoginScreen(
              authRepository: _authRepository,
              onSignedIn: _signedIn,
            ),
    );
  }
}
