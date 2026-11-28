import 'package:flutter/material.dart';
import '../app_state.dart';
import '../chat/chat_service.dart';
import '../core/theme.dart';

class ChatButton extends StatelessWidget {
  const ChatButton({super.key});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Assistant',
      icon: const Icon(Icons.auto_awesome),
      onPressed: () =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatScreen())),
    );
  }
}

class _Msg {
  _Msg(this.mine, this.text);
  final bool mine;
  final String text;
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [];
  bool _busy = false;

  static const _ideas = [
    'How do I scan a lot?',
    'How should I store milk before donating?',
    'What happens when a lot is blocked?',
    'How do offers work?',
  ];

  @override
  void initState() {
    super.initState();
    ChatService.instance.reset(); // every visit starts a fresh conversation
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _busy) return;
    setState(() {
      _msgs.add(_Msg(true, text));
      _busy = true;
      _input.clear();
    });
    _scrollDown();
    String answer;
    try {
      answer = await ChatService.instance.ask(text);
    } catch (e) {
      answer = aiErrorMessage(e);
    }
    if (!mounted) return;
    setState(() {
      _msgs.add(_Msg(false, answer));
      _busy = false;
    });
    _scrollDown();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant')),
      body: !s.cloud.enabled
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'The assistant needs Firebase and an internet connection. Finish the Firebase setup, then sign in with an account.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(children: [
              Container(
                width: double.infinity,
                color: Tokens.primaryLight,
                padding: const EdgeInsets.all(8),
                child: const Text(
                  'AI assistant. General guidance only. It can make mistakes and gives no legal clearance. The compliance check decides what can be donated.',
                  style: TextStyle(fontSize: 11),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (_msgs.isEmpty) ...[
                      const Text('Ask me about the app, or about handling food and medicine.'),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final q in _ideas)
                          ActionChip(label: Text(q), onPressed: () => _send(q)),
                      ]),
                    ],
                    for (final m in _msgs)
                      Align(
                        alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(10),
                          constraints:
                              BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                          decoration: BoxDecoration(
                            color: m.mine ? Tokens.primary : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(m.text,
                              style: TextStyle(color: m.mine ? Colors.white : Tokens.text)),
                        ),
                      ),
                    if (_busy)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Align(
                            alignment: Alignment.centerLeft, child: Text('Thinking…')),
                      ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                            hintText: 'Type your question',
                            border: OutlineInputBorder(),
                            isDense: true),
                      ),
                    ),
                    IconButton(onPressed: _busy ? null : _send, icon: const Icon(Icons.send)),
                  ]),
                ),
              ),
            ]),
    );
  }
}
