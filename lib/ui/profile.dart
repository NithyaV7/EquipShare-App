import 'package:flutter/material.dart';
import '../app_state.dart';
import '../core/theme.dart';
import '../data/geo.dart';
import '../domain/compliance.dart';
import '../models.dart';
import 'widgets.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return ListView(padding: const EdgeInsets.all(16), children: [
      const CircleAvatar(
          radius: 36,
          backgroundColor: Tokens.primaryLight,
          child: Icon(Icons.person, size: 40, color: Tokens.primary)),
      const SizedBox(height: 8),
      Text(s.userName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      Text(
        '${s.role == 'recipient' ? 'Recipient' : 'Donor'} · ${s.cloudMode ? 'cloud account' : 'demo mode'}',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      if (s.cloudMode && s.role == 'recipient' && s.profile != null)
        _ProfileEditor(s.profile!),
      if (s.role == 'donor') const _EsgFactors(),
      ListTile(
        leading: const Icon(Icons.shield_outlined),
        title: const Text('Safe-harbor rule set'),
        subtitle: Text(s.rules.version),
      ),
      SwitchListTile(
        secondary: const Icon(Icons.wifi_off),
        title: const Text('Simulate offline mode'),
        value: s.offline,
        onChanged: s.setOffline,
      ),
      if (!s.cloudMode)
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: const Text('Reset demo data'),
          onTap: () => showDialog<void>(
            context: context,
            builder: (dc) => AlertDialog(
              title: const Text('Reset demo data?'),
              content: const Text('This removes all lots, offers and custody logs on this device.'),
              actions: [
                TextButton(onPressed: () => Navigator.of(dc).pop(), child: const Text('Cancel')),
                TextButton(
                  onPressed: () {
                    s.resetDemo();
                    Navigator.of(dc).pop();
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
        ),
      const SizedBox(height: 12),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: Tokens.errorSurface, foregroundColor: Tokens.error),
        onPressed: s.signOut,
        child: const Text('Log out'),
      ),
    ]);
  }
}

/// Lets a recipient set what they accept, how much capacity is free, and where they are.
class _ProfileEditor extends StatefulWidget {
  const _ProfileEditor(this.p);
  final Recipient p;
  @override
  State<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<_ProfileEditor> {
  late final name = TextEditingController(text: widget.p.name);
  late bool food = widget.p.accepts.contains(LotCategory.food);
  late bool med = widget.p.accepts.contains(LotCategory.medicine);
  late double free = widget.p.freePct.toDouble();
  late double lat = widget.p.lat;
  late double lng = widget.p.lng;

  Future<void> locate() async {
    final p = await deviceLocation();
    if (!mounted) return;
    if (p == null) {
      snack(context, 'Could not get your location. Check location permission.');
      return;
    }
    setState(() {
      lat = p.lat;
      lng = p.lng;
    });
    snack(context, 'Location updated. Tap Save to keep it.');
  }

  void save() {
    if (!food && !med) {
      snack(context, 'Choose at least one thing you accept.');
      return;
    }
    AppScope.read(context).saveProfile(Recipient(
      id: widget.p.id,
      name: name.text.trim().isEmpty ? widget.p.name : name.text.trim(),
      emoji: widget.p.emoji,
      lat: lat,
      lng: lng,
      accepts: {if (food) LotCategory.food, if (med) LotCategory.medicine},
      freePct: free.round(),
    ));
    snack(context, 'Profile saved.');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Recipient profile (donors see this)',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Organisation name', border: OutlineInputBorder())),
          SwitchListTile(
              title: const Text('Accepts food'), value: food, onChanged: (v) => setState(() => food = v)),
          SwitchListTile(
              title: const Text('Accepts medicine'), value: med, onChanged: (v) => setState(() => med = v)),
          Text('Free capacity: ${free.round()}%'),
          Slider(
              value: free,
              min: 0,
              max: 100,
              divisions: 20,
              label: '${free.round()}%',
              onChanged: (v) => setState(() => free = v)),
          Row(children: [
            TextButton.icon(
                onPressed: locate, icon: const Icon(Icons.my_location), label: const Text('Use my location')),
            const Spacer(),
            ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(100, 44)),
                onPressed: save,
                child: const Text('Save')),
          ]),
        ]),
      ),
    );
  }
}

/// Lets a donor set the factors used in the ESG report.
class _EsgFactors extends StatefulWidget {
  const _EsgFactors();
  @override
  State<_EsgFactors> createState() => _EsgFactorsState();
}

class _EsgFactorsState extends State<_EsgFactors> {
  late final TextEditingController co2;
  late final TextEditingController rs;

  @override
  void initState() {
    super.initState();
    final s = AppScope.read(context);
    co2 = TextEditingController(text: '${s.co2PerKg}');
    rs = TextEditingController(text: '${s.rupeesPerKg}');
  }

  void save() {
    final c = double.tryParse(co2.text.trim());
    final r = double.tryParse(rs.text.trim());
    if (c == null || r == null || c < 0 || r < 0) {
      snack(context, 'Enter two numbers, zero or more.');
      return;
    }
    AppScope.read(context).setEsgFactors(c, r);
    snack(context, 'ESG factors saved.');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ESG report factors', style: TextStyle(fontWeight: FontWeight.w600)),
          const Text(
              'Use figures from your sustainability report or accountant. The report shows the values you enter.',
              style: TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          TextField(
            controller: co2,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'kg CO₂e avoided per kg donated', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: rs,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Rs. value per kg donated', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(100, 44)),
              onPressed: save,
              child: const Text('Save'),
            ),
          ),
        ]),
      ),
    );
  }
}
