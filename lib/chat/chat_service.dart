import 'package:firebase_ai/firebase_ai.dart';

/// The Gemini model used by the assistant. Google retires old model names over time.
/// If the assistant says it is not available, check the current model name in the
/// Firebase AI Logic documentation and change this one line.
const kAiModel = 'gemini-3.8-flash';

const _guide = '''
You are the EquiShare assistant, inside a mobile app that connects stores and pharmacies that have surplus food and medicine with local kitchens, clinics and food banks.

How the app works:
- Donors (stores, pharmacies): the Scan tab adds lots to a batch. Live scan (Android only) keeps the camera open and reads barcodes and expiry dates. Scan label takes one photo. Items can also be typed in. Then Review and clear lots runs the compliance check, Find recipients matches cleared lots to nearby recipients by distance and free capacity, and sending an offer notifies the recipient. The Custody tab shows a hash-linked log of every step. The ESG tab shows totals and exports a PDF. Profile holds the ESG factors and the Allow medicine lots switch, which is off by default.
- Recipients (kitchens, clinics, food banks): set the profile (what you accept, free capacity, location), then use Offers to accept or decline, and Track to confirm pickup and delivery.
- Offline: the pill at the top shows Offline or Synced. Lots scanned offline are queued and upload when the phone reconnects.
- Compliance check: expired lots are blocked, short-dated lots are flagged, restricted medicines are blocked, unreadable dates go to review. Medicine lots are held for review until the donor switches them on.

Rules for your answers:
- Be short and clear. Use plain words. Use at most 6 sentences unless asked for more.
- Never say that a food or medicine is safe, legal or approved to donate. The app's compliance check and the donor's own judgement decide, and the app gives no legal clearance.
- For food: give general handling advice such as keeping cold items cold, checking dates, and not donating anything damaged, opened, or with unreadable labels. Say that rules vary and to check with the local food-safety authority when unsure.
- For medicine: do not give dosing, diagnosis or treatment advice. Say that redistributing medicine is regulated and the user should check with the medicines regulator or a pharmacist.
- Only describe app features listed above. If you do not know something about the app, say so.
- If a question is unrelated to EquiShare, food donation or food and medicine handling, politely say you can only help with those.
''';

/// Talks to Gemini through Firebase AI Logic. No API key is stored in the app.
class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  GenerativeModel? _model;
  ChatSession? _chat;

  GenerativeModel _m() => _model ??= FirebaseAI.googleAI().generativeModel(
        model: kAiModel,
        systemInstruction: Content.system(_guide),
      );

  /// Starts a new conversation.
  void reset() => _chat = null;

  Future<String> ask(String message) async {
    _chat ??= _m().startChat();
    final r = await _chat!.sendMessage(Content.text(message));
    final t = r.text?.trim();
    if (t == null || t.isEmpty) return 'I could not answer that. Please try asking in another way.';
    return t;
  }

  /// Suggests an item name and a short handling note from label text.
  /// First line is the name, the following text is the note.
  Future<String> suggest(String labelText) async {
    final prompt = '''
Here is text read from a product label by a scanner. It may contain mistakes.

$labelText

Reply with exactly two lines.
Line 1: a short product name, at most 6 words, with no brand slogans.
Line 2: one short storage or handling note, for example "Keep refrigerated" or "Keep dry and sealed".
If you cannot tell what the product is, reply with "Unknown item" on line 1 and "Check the label by eye" on line 2.
Do not say whether it is safe or allowed to donate.
''';
    final r = await _m().generateContent([Content.text(prompt)]);
    return r.text?.trim() ?? '';
  }
}

/// Turns an error into a message people can act on.
String aiErrorMessage(Object e) {
  final t = e.toString();
  final lower = t.toLowerCase();
  String why;
  if (lower.contains('socket') ||
      lower.contains('network') ||
      lower.contains('host lookup') ||
      lower.contains('unavailable')) {
    why = 'No internet connection. The assistant needs internet.';
  } else if (lower.contains('quota') || lower.contains('429') || lower.contains('rate')) {
    why = 'The assistant is busy or the free limit was reached. Try again in a minute.';
  } else if (lower.contains('not found') ||
      lower.contains('404') ||
      lower.contains('permission') ||
      lower.contains('403') ||
      lower.contains('has not been used') ||
      lower.contains('disabled')) {
    why = 'The assistant is not switched on for this project yet. In the Firebase console, open AI Logic and enable the Gemini Developer API. The model name may also need updating.';
  } else {
    why = 'The assistant could not answer right now.';
  }
  final detail = t.length > 120 ? '${t.substring(0, 120)}…' : t;
  return '$why\n\n($detail)';
}
