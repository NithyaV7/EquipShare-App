import 'package:flutter/material.dart';
import '../app_state.dart';
import '../core/theme.dart';
import 'widgets.dart';

/// Bell icon with an unread counter, shown in the top bar.
class NotificationsButton extends StatelessWidget {
  const NotificationsButton({super.key});
  @override
  Widget build(BuildContext context) {
    final n = AppScope.of(context).unreadNotes;
    return IconButton(
      tooltip: 'Notifications',
      onPressed: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
      icon: Badge(
        isLabelVisible: n > 0,
        label: Text('$n'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.read(context).markNotesRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = AppScope.of(context).myNotes;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: list.isEmpty
          ? const Center(child: Text('Nothing new yet.'))
          : ListView(padding: const EdgeInsets.all(16), children: [
              for (final n in list)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Tokens.primaryLight,
                      child: Icon(Icons.notifications, color: Tokens.primary),
                    ),
                    title: Text(n.title),
                    subtitle: Text('${n.body}\n${fmtTime(n.time)}'),
                    isThreeLine: true,
                  ),
                ),
            ]),
    );
  }
}
