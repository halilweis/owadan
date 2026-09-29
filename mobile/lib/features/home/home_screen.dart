import 'package:flutter/material.dart';

import '../auth/auth_repository.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.authRepository,
    required this.onSignedOut,
    super.key,
  });
  final AuthRepository authRepository;
  final VoidCallback onSignedOut;

  Future<void> _logout() async {
    await authRepository.logout();
    onSignedOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owadan'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: const Center(
        child: Text(
          'Authentication connected.\nNext: categories and professional discovery.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
