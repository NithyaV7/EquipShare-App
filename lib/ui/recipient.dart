import 'package:flutter/material.dart';
import '../app_state.dart';
import '../core/theme.dart';
import '../models.dart';
import 'notifications.dart';
import 'profile.dart';
import 'widgets.dart';

class RecipientShell extends StatefulWidget {
  const RecipientShell({super.key});
  @override
  State<RecipientShell> createState() => _RecipientShellState();
}

class _RecipientShellState extends State<RecipientShell> {
  int i = 0;
  @override
  Widget build(BuildContext context) {
    const titles = ['EquiShare', 'Offers', 'Pickup tracking', 'Profile'];
    return Scaffold(
      appBar: AppBar(title: Text(titles[i]), actions: const [NotificationsButton(), SyncPill()]),
      body: IndexedStack(index: i, children: const [
        RecipientHome(),
        OffersTab(),
        TrackTab(),
        ProfileTab(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: i,
        onDestinationSelected: (n) => setState(() => i = n),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), label: 'Offers'),
          NavigationDestination(icon: Icon(Icons.local_shipping_outlined), label: 'Track'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

Widget offerCard(BuildContext context, AppState s, Offer o) {
  final lots = s.lotsOf(o);
  return Card(
    margin: const EdgeInsets.only(top: 10),
    child: ListTile(
      leading: const CircleAvatar(
          backgroundColor: Tokens.primaryLight, child: Icon(Icons.store, color: Tokens.primary)),
      title: const Text('Greenleaf Grocers'),
      subtitle: Text('${lots.length} lots · ${o.status.replaceAll('_', ' ')}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => OfferScreen(o))),
    ),
  );
}

class RecipientHome extends StatelessWidget {
  const RecipientHome({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final pending = s.myOffers.where((o) => o.status == 'pending').toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Hello, ${s.userName}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),
      StatCard("Today's capacity", '${s.profile?.freePct ?? 70}% free',
          sub: s.cloudMode ? 'Edit this in Profile' : 'Demo recipient'),
      const SizedBox(height: 12),
      const Text('Incoming offers', style: TextStyle(fontWeight: FontWeight.w600)),
      if (pending.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text('No new offers. Offers from donors appear here.'),
        ),
      for (final o in pending) offerCard(context, s, o),
    ]);
  }
}

class OffersTab extends StatelessWidget {
  const OffersTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final list = s.myOffers;
    if (list.isEmpty) return const Center(child: Text('No offers yet.'));
    return ListView(padding: const EdgeInsets.all(16), children: [
      for (final o in list) offerCard(context, s, o),
    ]);
  }
}

class OfferScreen extends StatelessWidget {
  const OfferScreen(this.offer, {super.key});
  final Offer offer;
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Offer details')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('From Greenleaf Grocers. Every lot below passed the compliance check and is logged in the chain of custody.'),
        for (final l in s.lotsOf(offer)) LotTile(l),
        const SizedBox(height: 16),
        if (offer.status == 'pending') ...[
          ElevatedButton(
            onPressed: () {
              s.respond(offer, true);
              Navigator.of(context).pop();
            },
            child: const Text('Accept offer'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () {
              s.respond(offer, false);
              Navigator.of(context).pop();
            },
            child: const Text('Decline'),
          ),
        ] else
          Text('Status: ${offer.status.replaceAll('_', ' ')}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class TrackTab extends StatelessWidget {
  const TrackTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final active = s.myOffers
        .where((o) => o.status == 'accepted' || o.status == 'picked_up')
        .toList();
    if (active.isEmpty) {
      return const Center(child: Text('Accept an offer to track its pickup here.'));
    }
    return ListView(padding: const EdgeInsets.all(16), children: [
      for (final o in active)
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Offer from Greenleaf Grocers · ${s.lotsOf(o).length} lots',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              StepTracker(o.step),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => s.advance(o),
                child: Text(o.status == 'accepted' ? 'Confirm pickup' : 'Confirm delivery'),
              ),
            ]),
          ),
        ),
    ]);
  }
}
