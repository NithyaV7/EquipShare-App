import 'package:flutter/material.dart';
import '../app_state.dart';
import '../core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final pw = TextEditingController();
  String chosen = 'donor';
  String? error;
  bool busy = false;

  Future<void> go(bool register) async {
    final s = AppScope.read(context);
    if (email.text.trim().isEmpty || pw.text.length < 6) {
      setState(() => error = 'Enter your email and a password of at least 6 characters.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    final err = await s.signInCloud(
      email: email.text.trim(),
      password: pw.text,
      chosenRole: chosen,
      register: register,
    );
    if (mounted) {
      setState(() {
        busy = false;
        error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const SizedBox(height: 24),
          const Icon(Icons.eco, size: 56, color: Tokens.primary),
          const SizedBox(height: 8),
          const Text('EquiShare',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: Tokens.primary)),
          const Text('Share More. Waste Less.', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          if (s.cloud.enabled) ...[
            TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: pw,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            const Text('I am a (used when creating an account)'),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'donor', label: Text('Donor')),
                ButtonSegment(value: 'recipient', label: Text('Recipient')),
              ],
              selected: {chosen},
              onSelectionChanged: (v) => setState(() => chosen = v.first),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(error!, style: const TextStyle(color: Tokens.error)),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: busy ? null : () => go(false),
              child: Text(busy ? 'Please wait…' : 'Sign in'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: busy ? null : () => go(true), child: const Text('Create account')),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('or try the demo without an account', textAlign: TextAlign.center),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Cloud sync is not set up, so the app runs in demo mode. Data stays on this device.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ),
          OutlinedButton(
            onPressed: () => s.signInDemo('donor'),
            child: const Text('Demo · Donor (store or pharmacy)'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => s.signInDemo('recipient'),
            child: const Text('Demo · Recipient (kitchen, clinic, food bank)'),
          ),
        ]),
      ),
    );
  }
}
