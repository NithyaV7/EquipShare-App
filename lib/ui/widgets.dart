import 'package:flutter/material.dart';
import '../app_state.dart';
import '../core/theme.dart';
import '../domain/compliance.dart';
import '../models.dart';

String two(int n) => n.toString().padLeft(2, '0');
String fmtDate(DateTime? d) => d == null ? 'unknown' : '${two(d.day)}/${two(d.month)}/${d.year}';
String fmtTime(DateTime d) => '${fmtDate(d)} ${two(d.hour)}:${two(d.minute)}';
IconData catIcon(LotCategory c) => c == LotCategory.food ? Icons.restaurant : Icons.medication;

/// Tap to switch between online and offline (simulated).
class SyncPill extends StatelessWidget {
  const SyncPill({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ActionChip(
        backgroundColor: s.offline ? Tokens.warning : Tokens.primaryLight,
        label: Text(
          s.offline ? 'Offline · ${s.queuedCount} queued' : 'Synced',
          style: const TextStyle(fontSize: 12),
        ),
        onPressed: () => s.setOffline(!s.offline),
      ),
    );
  }
}

class VerdictBadge extends StatelessWidget {
  const VerdictBadge(this.v, {super.key});
  final Verdict v;
  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (v) {
      Verdict.cleared => (Tokens.primaryLight, const Color(0xFF173D1C), 'Cleared'),
      Verdict.flagged => (const Color(0xFFFFE9B8), const Color(0xFF5A3C00), 'Flagged'),
      Verdict.blocked => (Tokens.errorSurface, Tokens.error, 'Blocked'),
      Verdict.review => (const Color(0xFFE3E8EA), Tokens.text, 'Review'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard(this.title, this.value, {super.key, this.sub});
  final String title;
  final String value;
  final String? sub;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Tokens.primary, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
        if (sub != null) Text(sub!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }
}

class LotTile extends StatelessWidget {
  const LotTile(this.lot, {super.key, this.trailing});
  final Lot lot;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Tokens.primaryLight,
          child: Icon(catIcon(lot.category), color: Tokens.primary),
        ),
        title: Text(lot.name),
        subtitle: Text(
          '${lot.barcode.isEmpty ? 'no barcode' : lot.barcode} · exp ${fmtDate(lot.expiry)}\n${lot.reason}',
        ),
        isThreeLine: true,
        trailing: trailing ?? VerdictBadge(lot.verdict),
      ),
    );
  }
}

class StepTracker extends StatelessWidget {
  const StepTracker(this.step, {super.key});
  final int step;
  @override
  Widget build(BuildContext context) {
    const labels = ['Offered', 'Accepted', 'Picked up', 'Delivered'];
    return Row(children: [
      for (var i = 0; i < 4; i++)
        Expanded(
          child: Column(children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: i <= step ? Tokens.primary : const Color(0xFFDFE9E0),
              child: i <= step ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(height: 4),
            Text(labels[i], style: const TextStyle(fontSize: 11)),
          ]),
        ),
    ]);
  }
}

void snack(BuildContext c, String msg) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(msg)));
