import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_state.dart';
import 'cloud/cloud_factory.dart';
import 'core/theme.dart';
import 'data/store.dart';
import 'domain/compliance.dart';
import 'ui/auth.dart';
import 'ui/donor.dart';
import 'ui/recipient.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.init();
  final json = await rootBundle.loadString('assets/rules_v1.json');
  final rules = RuleSet.fromJson(jsonDecode(json) as Map<String, dynamic>);
  final cloud = await createCloud();
  final state = AppState(rules, cloud)
    ..load()
    ..start();
  runApp(EquiShareApp(state));
}

class EquiShareApp extends StatelessWidget {
  const EquiShareApp(this.state, {super.key});
  final AppState state;
  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'EquiShare',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const Root(),
      ),
    );
  }
}

class Root extends StatelessWidget {
  const Root({super.key});
  @override
  Widget build(BuildContext context) {
    final role = AppScope.of(context).role;
    if (role == 'donor') return const DonorShell();
    if (role == 'recipient') return const RecipientShell();
    return const LoginScreen();
  }
}
