# The AI assistant

The assistant answers questions about the app and general food and medicine handling, and it can suggest an item name from a scanned label. It uses Google's Gemini through Firebase AI Logic. No key is stored in the app.

## Switch it on (about 3 minutes)
1. Open the Firebase console and your project.
2. Open **AI services** in the left menu, then **AI Logic**. You can also use the search box and type `AI Logic`.
3. Click **Get started**.
4. Choose **Gemini Developer API** and follow the prompts. This works on the free Spark plan. It creates a key inside your project. Do not copy that key anywhere.
5. Open the app, sign in with an account, and tap the sparkle icon at the top of any screen.

## Where it shows up
- The sparkle icon at the top of every screen opens the chat.
- On the Scan tab, **Suggest name with AI** reads the label text and proposes a name and a short handling note. You choose whether to use it.

## Limits and safety
- It needs internet and a signed-in account. Offline, it shows a message.
- The free tier has rate limits. If you reach them it says to try again later.
- It gives general guidance only. It is told never to say that a food or medicine is safe, legal or approved to donate, and never to give dosing or diagnosis advice. The compliance check stays in charge.
- Chat messages and label text you ask about are sent to Google's Gemini service. Tell testers not to type personal details. Mention this in your project's privacy notes.
- Anyone who has your app can reach the assistant, so heavy misuse could use up the free limit. Firebase App Check is the standard protection. Add it later if the app is released to the public.

## If it says it is not available
1. Check that AI Logic is switched on with the Gemini Developer API (steps above).
2. Google retires older model names. The name is a single line, `kAiModel`, in `lib/chat/chat_service.dart`. Look up the current model names in the Firebase AI Logic documentation and change that line.
3. The error text appears in brackets under the message. Send it to me if you need help.
