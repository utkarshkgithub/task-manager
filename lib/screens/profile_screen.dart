import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.authService});

  final AuthService authService;

  Future<void> _signOut(BuildContext context) async {
    await authService.signOut();
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Signed out successfully.')));
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Unknown';
    }

    return DateFormat('MMM d, y • h:mm a').format(dateTime.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final User? user = authService.currentUser;

    if (user == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final displayName = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : 'Task Manager user';
    final providerIds = user.providerData
        .map((provider) => provider.providerId)
        .where((providerId) => providerId.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: Colors.black,
                child: Icon(Icons.person, color: Colors.grey,size: 54,)
              ),
              const SizedBox(height: 20),
              _InfoSection(
                title: 'Personal details',
                children: [
                  _InfoRow(label: 'Display name', value: displayName),
                  _InfoRow(label: 'Email', value: user.email ?? 'Not set'),
                ],
              ),
              const SizedBox(height: 16),
              _InfoSection(
                title: 'Security',
                children: [
                  _InfoRow(
                    label: 'Email verified',
                    value: user.emailVerified ? 'Verified' : 'Not verified',
                  ),
                  _InfoRow(
                    label: 'Created',
                    value: _formatDate(user.metadata.creationTime),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _signOut(context),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF888888),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
