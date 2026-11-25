import 'package:flutter/material.dart';
import '../app_state.dart';
import '../core/theme.dart';
import '../data/custody.dart';
import '../domain/compliance.dart';
import '../domain/date_parser.dart';
import '../data/report.dart';
import '../models.dart';
import '../scan/scanner_stub.dart' if (dart.library.io) '../scan/scanner_mlkit.dart';
import 'profile.dart';
import 'widgets.dart';

class DonorShell extends StatefulWidget {
  const DonorShell({super.key});
  @override
  State<DonorShell> createState() => _DonorShellState();
}

class _DonorShellState extends State<DonorShell> {
  int i = 0;
  @override
  Widget build(BuildContext context) {
    const titles = ['EquiShare', 'Batch scan', 'Chain of custody', 'ESG report', 'Profile'];
    return Scaffold(
      appBar: AppBar(title: Text(titles[i]), actions: const [SyncPill()]),
      body: IndexedStack(index: i, children: [
        DonorHome(onTab: (n) => setState(() => i = n)),
        const ScanTab(),
        const CustodyTab(),
        const EsgTab(),
        const ProfileTab(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        onDestinationSelected: (n) => setState(() => i = n),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.link), label: 'Custody'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'ESG'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class DonorHome extends StatelessWidget {
  const DonorHome({super.key, required this.onTab});
  final void Function(int) onTab;

  Widget action(IconData icon, String label, VoidCallback f) => InkWell(
        onTap: f,
        child: Column(children: [
          CircleAvatar(
              radius: 25, backgroundColor: Tokens.primaryLight, child: Icon(icon, color: Tokens.primary)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final recent = s.lots.reversed.take(5).toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Hello, ${s.userName}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      StatCard('Delivered so far', '${s.deliveredKg.toStringAsFixed(1)} kg',
          sub: '${s.deliveredLots.length} lots · ${s.batch.length} waiting in current batch'),
      Card(
        margin: const EdgeInsets.only(top: 12),
        child: ListTile(
          leading: const Icon(Icons.sync),
          title: const Text('Sync queue'),
          subtitle: Text('${s.queuedCount} lots waiting to upload'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const QueueScreen())),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          action(Icons.qr_code_scanner, 'Batch scan', () => onTab(1)),
          action(Icons.shield_outlined, 'Compliance', () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const GateScreen()))),
          action(Icons.link, 'Custody', () => onTab(2)),
          action(Icons.bar_chart, 'ESG', () => onTab(3)),
        ]),
      ),
      const Text('Recent lots', style: TextStyle(fontWeight: FontWeight.w600)),
      if (recent.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text('Nothing scanned yet. Open the Scan tab to add your first lot.'),
        ),
      for (final l in recent) LotTile(l),
    ]);
  }
}

class ScanTab extends StatefulWidget {
  const ScanTab({super.key});
  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> {
  final label = TextEditingController();
  final name = TextEditingController();
  final barcode = TextEditingController();
  final kg = TextEditingController(text: '1');
  LotCategory cat = LotCategory.food;
  DateTime? expiry;
  double? conf;
  int sample = 0;

  void readDate() {
    final p = parseExpiryFromText(label.text);
    setState(() {
      expiry = p?.date;
      conf = p?.confidence;
    });
    if (p == null) snack(context, 'No date found. Pick one manually.');
  }

  Future<void> scan(bool gallery) async {
    try {
      final r = await scanLabel(fromGallery: gallery);
      if (r == null) return;
      final firstLine = r.text.split('\n').map((e) => e.trim()).firstWhere((e) => e.isNotEmpty, orElse: () => '');
      setState(() {
        label.text = r.text;
        if (r.barcode != null) barcode.text = r.barcode!;
        if (name.text.isEmpty) name.text = firstLine;
      });
      readDate();
      if (mounted && r.barcode == null) snack(context, 'No barcode found. Type it in if you need it.');
    } catch (e) {
      if (mounted) snack(context, 'Could not read the image: $e');
    }
  }

  void useSample() {
    final items = [
      ('Whole Milk 1L', '5012345678900', LotCategory.food, 3),
      ('Paracetamol 500mg', '6291041500213', LotCategory.medicine, 53),
      ('Yoghurt 400g', '4800016644801', LotCategory.food, -4),
      ('Tramadol 50mg', '8901030865278', LotCategory.medicine, 100),
    ];
    final it = items[sample % items.length];
    sample++;
    final d = DateTime.now().add(Duration(days: it.$4));
    setState(() {
      name.text = it.$1;
      barcode.text = it.$2;
      cat = it.$3;
      label.text = 'EXP ${fmtDate(d)}';
    });
    readDate();
  }

  Future<void> pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: expiry ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (d != null && mounted) {
      setState(() {
        expiry = d;
        conf = 1.0;
      });
    }
  }

  void add() {
    if (name.text.trim().isEmpty) {
      snack(context, 'Enter the item name.');
      return;
    }
    AppScope.read(context).addLot(
      name: name.text.trim(),
      barcode: barcode.text.trim(),
      category: cat,
      expiry: expiry,
      kg: double.tryParse(kg.text) ?? 1,
    );
    setState(() {
      name.clear();
      barcode.clear();
      label.clear();
      kg.text = '1';
      expiry = null;
      conf = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = conf;
    final dateText = expiry == null
        ? 'No date yet'
        : 'Expiry ${fmtDate(expiry)}${c != null && c < 0.8 ? ' · low confidence, please confirm' : ''}';
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (scannerSupported)
        Row(children: [
          Expanded(
              child: ElevatedButton.icon(
                  onPressed: () => scan(false),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Scan label'))),
          const SizedBox(width: 8),
          Expanded(
              child: OutlinedButton.icon(
                  onPressed: () => scan(true),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('From gallery'))),
        ])
      else
        const Text('Camera scanning works in the Android app. Here, paste or type the label text.',
            style: TextStyle(fontSize: 12)),
      const SizedBox(height: 8),
      TextField(
        controller: label,
        maxLines: 2,
        decoration: const InputDecoration(
            labelText: 'Label text', hintText: 'e.g. EXP 25/11/2026', border: OutlineInputBorder()),
      ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: useSample, child: const Text('Use sample'))),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton(onPressed: readDate, child: const Text('Read date'))),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: Text(dateText)),
        TextButton(onPressed: pickDate, child: const Text('Pick date')),
      ]),
      TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Item name', border: OutlineInputBorder())),
      const SizedBox(height: 8),
      TextField(
          controller: barcode,
          decoration: const InputDecoration(labelText: 'Barcode', border: OutlineInputBorder())),
      const SizedBox(height: 8),
      TextField(
          controller: kg,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder())),
      const SizedBox(height: 8),
      SegmentedButton<LotCategory>(
        segments: const [
          ButtonSegment(value: LotCategory.food, label: Text('Food')),
          ButtonSegment(value: LotCategory.medicine, label: Text('Medicine')),
        ],
        selected: {cat},
        onSelectionChanged: (v) => setState(() => cat = v.first),
      ),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: add, child: const Text('Add to batch')),
      const SizedBox(height: 16),
      Text('Current batch (${s.batch.length})', style: const TextStyle(fontWeight: FontWeight.w600)),
      for (final l in s.batch) LotTile(l),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: s.batch.isEmpty
            ? null
            : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GateScreen())),
        child: const Text('Review and clear lots'),
      ),
    ]);
  }
}

class GateScreen extends StatelessWidget {
  const GateScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final b = s.batch;
    final ok = b.where((l) => l.cleared).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Compliance check')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('$ok cleared, ${b.length - ok} not cleared. Screened against rule set ${s.rules.version}.'),
        if (b.isEmpty) const Padding(padding: EdgeInsets.only(top: 16), child: Text('The batch is empty.')),
        for (final l in b)
          LotTile(l,
              trailing: l.cleared
                  ? const VerdictBadge(Verdict.cleared)
                  : TextButton(onPressed: () => s.discard(l), child: const Text('Remove'))),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: ok == 0
              ? null
              : () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const MatchScreen())),
          child: const Text('Find recipients for cleared lots'),
        ),
      ]),
    );
  }
}

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});
  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  int radius = 5;
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final list = s.matches(radius);
    return Scaffold(
      appBar: AppBar(title: const Text('Matching'), actions: [
        if (s.cloudMode)
          IconButton(
              tooltip: 'Refresh recipients',
              icon: const Icon(Icons.refresh),
              onPressed: s.refreshRecipients),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Wrap(spacing: 8, children: [
          for (final r in [3, 5, 10])
            ChoiceChip(
                label: Text('$r km'), selected: radius == r, onSelected: (_) => setState(() => radius = r)),
        ]),
        Row(children: [
          Expanded(
              child: Text(
                  s.deviceLoc ? 'Using your device location' : 'Using a demo location in Colombo',
                  style: const TextStyle(fontSize: 12))),
          TextButton(
            onPressed: () async {
              final ok = await s.useMyLocation();
              if (!ok && mounted) {
                snack(context, 'Could not get your location. Check location permission.');
              }
            },
            child: const Text('Use my location'),
          ),
        ]),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(s.cloudMode
                ? 'No registered recipient within this radius accepts your cleared lots. Try a larger radius or refresh.'
                : 'No recipients in this radius accept your cleared lots. Try a larger radius.'),
          ),
        for (final r in list)
          Card(
            margin: const EdgeInsets.only(top: 10),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Tokens.primaryLight, child: Text(r.emoji)),
              title: Text(r.name),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${s.distanceKm(r).toStringAsFixed(1)} km · accepts ${r.accepts.map((c) => c.name).join(', ')}'),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: r.freePct / 100),
              ]),
              trailing: Text('${r.freePct}% free'),
              onTap: () {
                final o = s.dispatch(r);
                if (o != null) {
                  Navigator.of(context)
                      .pushReplacement(MaterialPageRoute(builder: (_) => DispatchScreen(r)));
                }
              },
            ),
          ),
      ]),
    );
  }
}

class DispatchScreen extends StatelessWidget {
  const DispatchScreen(this.r, {super.key});
  final Recipient r;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dispatch sent')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.check_circle, size: 80, color: Tokens.primary),
          const SizedBox(height: 12),
          Text('${r.name} has been notified.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('The recipient can accept it in their app. Each step is added to the custody log.',
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('Back to home')),
        ]),
      ),
    );
  }
}

const _eventNames = {
  'scanned': 'Scanned',
  'cleared': 'Compliance cleared',
  'blocked': 'Blocked by compliance',
  'discarded': 'Removed from batch',
  'dispatched': 'Dispatched',
  'accepted': 'Accepted by recipient',
  'declined': 'Declined by recipient',
  'picked_up': 'Picked up',
  'delivered': 'Delivered',
};

class CustodyTab extends StatelessWidget {
  const CustodyTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final lots = s.lots.reversed.toList();
    if (lots.isEmpty) return const Center(child: Text('Scan a lot to start its custody log.'));
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Entries are linked by hashes. Any edit breaks the chain and is detected.',
          style: TextStyle(fontSize: 12)),
      for (final l in lots)
        Builder(builder: (_) {
          final chain = s.chainFor(l.id);
          final ok = verifyChain(chain);
          return Card(
            margin: const EdgeInsets.only(top: 10),
            child: ExpansionTile(
              title: Text(l.name),
              subtitle: Text(ok ? 'Chain verified · ${chain.length} entries' : 'Chain broken'),
              children: [
                for (final e in chain)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.circle, size: 10, color: Tokens.primary),
                    title: Text(_eventNames[e.event] ?? e.event),
                    subtitle: Text(
                        '${fmtTime(DateTime.parse(e.timestamp).toLocal())} · #${e.hash.substring(0, 8)}'),
                  ),
              ],
            ),
          );
        }),
    ]);
  }
}

class EsgTab extends StatelessWidget {
  const EsgTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final kg = s.deliveredKg;
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    final months = [for (var i = 4; i >= 0; i--) DateTime(now.year, now.month - i)];
    final perMonth = [
      for (final m in months)
        s.deliveredLots
            .where((l) => l.createdAt.year == m.year && l.createdAt.month == m.month)
            .fold(0.0, (a, l) => a + l.kg)
    ];
    final maxKg = perMonth.fold(1.0, (a, b) => b > a ? b : a);
    return ListView(padding: const EdgeInsets.all(16), children: [
      StatCard('Delivered', '${kg.toStringAsFixed(1)} kg', sub: '${s.deliveredLots.length} lots'),
      const SizedBox(height: 10),
      Card(
        child: ListTile(
          leading: const Icon(Icons.co2),
          title: Text('${(kg * AppState.co2PerKg).toStringAsFixed(1)} kg CO₂e avoided (estimate)'),
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.payments_outlined),
          title: Text('Rs. ${(kg * AppState.rupeesPerKg).toStringAsFixed(0)} donation value (estimate)'),
        ),
      ),
      const SizedBox(height: 12),
      const Text('Kilograms per month', style: TextStyle(fontWeight: FontWeight.w600)),
      for (var i = 0; i < months.length; i++)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(children: [
            SizedBox(width: 36, child: Text(names[months[i].month - 1])),
            Expanded(child: LinearProgressIndicator(value: perMonth[i] / maxKg, minHeight: 10)),
            SizedBox(width: 48, child: Text(' ${perMonth[i].toStringAsFixed(1)}')),
          ]),
        ),
      const SizedBox(height: 16),
      const Text(
          'Estimates use placeholder factors (2.5 kg CO₂e and Rs. 600 per kg). Replace them with figures your accountant or regulator accepts.',
          style: TextStyle(fontSize: 12)),
      const SizedBox(height: 12),
      OutlinedButton(onPressed: () => exportEsgPdf(s), child: const Text('Export PDF report')),
    ]);
  }
}

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Sync queue'), actions: const [SyncPill()]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Tap the pill at the top to go offline or online. Lots scanned offline are saved on this device and queued.'),
        if (s.lots.isEmpty) const Padding(padding: EdgeInsets.only(top: 16), child: Text('No lots yet.')),
        for (final l in s.lots.reversed)
          Card(
            margin: const EdgeInsets.only(top: 10),
            child: ListTile(
              leading: Icon(catIcon(l.category), color: Tokens.primary),
              title: Text(l.name),
              subtitle: const Text('Saved on this device'),
              trailing: Text(l.synced ? 'Synced' : 'Queued',
                  style: TextStyle(color: l.synced ? Tokens.primary : Tokens.error)),
            ),
          ),
      ]),
    );
  }
}
