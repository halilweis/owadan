import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/localization/app_localizations.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/otp_login_screen.dart';
import 'features/booking/booking_repository.dart';
import 'features/discovery/discovery_repository.dart';
import 'features/home/home_screen.dart';
import 'features/profile/profile_repository.dart';
import 'core/localization/api_error_messages.dart';

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
  Locale _locale = const Locale('en');

  @override
  void initState() {
    super.initState();

    final systemCode =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    if (AppLocalizations.supports(systemCode)) {
      _locale = Locale(systemCode);
      ApiErrorMessages.setLanguage(_locale.languageCode);
    }

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

    final authenticated =
        (accessToken != null && accessToken.isNotEmpty) ||
        (refreshToken != null && refreshToken.isNotEmpty);

    if (authenticated) {
      await _loadPreferredLocale();
    }

    if (!mounted) return;

    setState(() {
      _authenticated = authenticated;
      _loading = false;
    });
  }

  Future<void> _loadPreferredLocale() async {
    try {
      final user = await _profileRepository.fetchMe();
      _setLocale(user.preferredLanguage, rebuild: false);
    } catch (_) {
      // Keep the current/system locale if the profile cannot be loaded yet.
    }
  }

  void _signedIn() {
    setState(() {
      _authenticated = true;
    });
    _loadPreferredLocale().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _signedOut() {
    setState(() {
      _authenticated = false;
    });
  }

  void _setLocale(String languageCode, {bool rebuild = true}) {
    final normalized =
        AppLocalizations.supports(languageCode) ? languageCode : 'en';

    ApiErrorMessages.setLanguage(normalized);

    if (_locale.languageCode == normalized) {
      return;
    }

    if (rebuild && mounted) {
      setState(() {
        _locale = Locale(normalized);
      });
    } else {
      _locale = Locale(normalized);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Owadan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,

        // Flutter does not currently provide built-in Material/Cupertino
        // localizations for Turkmen. These delegates provide framework
        // fallbacks while Owadan's own text remains Turkmen.
        TurkmenMaterialLocalizationsDelegate(),
        TurkmenCupertinoLocalizationsDelegate(),

        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _authenticated
          ? HomeScreen(
              authRepository: _authRepository,
              discoveryRepository: _discoveryRepository,
              bookingRepository: _bookingRepository,
              profileRepository: _profileRepository,
              onSignedOut: _signedOut,
              onLanguageChanged: _setLocale,
            )
          : OtpLoginScreen(
              authRepository: _authRepository,
              onSignedIn: _signedIn,
            ),
    );
  }
}
