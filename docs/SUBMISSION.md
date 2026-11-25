# Sauti | #BuildHybridAI 2026 submission draft

- **Platform** — Web (Chrome)
- **Deadline** — November 30 at 2 p.m. Pacific / December 1 at 00:00 in Bujumbura
- [Devpost official rules](https://firebasehybridaihackathon.devpost.com/rules)

## Devpost project description

**Title** — Sauti, voice banking across unreliable connections

**One-line summary** — Sauti helps people with low vision in Burundi check a balance, understand a payment, and review a transfer through speech or text, with Firebase AI Logic choosing between on-device and cloud inference.

### Inspiration

Checking a balance should be a task you can do privately. For someone with low vision, that task can involve reading a small amount, finding the right account, and navigating a screen full of competing controls. An unreliable connection can interrupt the same task. Sauti explores a banking interface in which you can ask one question, hear the answer, and tell when the balance was last synced.

### What it does

Ask “How much money do I have?” and Sauti shows a balance card from a typed banking tool. The reply can be read aloud. If connectivity drops after the balance has been synced, Sauti can show the last saved balance and its timestamp. Outgoing transfers require a connection.

Ask Sauti to send money to a saved beneficiary and it drafts the transfer for review. The app shows the recipient, amount, and fee before the user authenticates and presses Send. The demo bank uses fictitious accounts and funds.

The interface supports English, French, and Kirundi. Users can type or use the microphone and adjust text size, contrast, movement, and spoken replies. Speech recognition and device voices depend on the selected language and platform. Kirundi speech support should be described from the recorded device.

### How we used Firebase AI Logic

On desktop Chrome, Sauti’s Flutter web bridge uses the Firebase AI Logic JavaScript SDK in `PREFER_ON_DEVICE` mode when cloud AI is allowed. The SDK chooses Gemini Nano when it is available and cloud Gemini otherwise. The model classifies the user’s request as a structured intent. Sauti validates the intent, calls a typed banking tool, and renders the result in a reply and card. The classifier receives user requests without prior assistant replies or banking tool results. More open-ended requests can use the full Firebase AI Logic cloud agent, which receives conversation context and selected tool data. A deterministic intent engine covers common tasks without a model.

The assistant identifies how each reply was generated. Whether the user speaks or types, the transfer tools only prepare and present drafts. Authentication and final submission live in the transfer screen. Cloud requests use Firebase App Check.

| Runtime path | Source |
|---|---|
| Chrome hybrid SDK initialization, generation and inference source | [Web bridge](../packages/sauti_hybrid_ai/lib/src/web_hybrid_ai.dart) |
| Structured intent, tool execution and reply rendering | [Hybrid intent provider](../lib/features/ai_agent/data/on_device/hybrid_intent_provider.dart) |
| Cloud Gemini and typed function calls | [Gemini provider](../lib/features/ai_agent/data/cloud/gemini_ai_provider.dart) |
| Tool selection and provider fallback | [Orchestrator](../lib/features/ai_agent/domain/services/agent_orchestrator.dart) |
| User-approved transfer submission | [Submit transfer use case](../lib/features/transfers/domain/usecases/submit_transfer.dart) |

### What we built during the submission period

The first Sauti commit is dated November 15, 2026. During the event we built the Flutter banking demo, the voice and text assistant, accessibility controls, the simulated bank and Firebase sandbox adapters, and the hybrid inference bridge for Chrome, Android, and iOS. The demo is centered on Chrome. The Android and iOS implementations need separate device validation.

Sauti started from a Flutter project template and uses the open-source dependencies in `pubspec.yaml`. The existing project draft records Claude Code use. Codex reviewed the implementation, ran automated checks, and helped refine the UI and submission evidence. Confirm any additional tools or pre-existing work before copying the disclosure to Devpost.

### What's next

Observe a balance check and transfer review with people with low vision in Bujumbura, refine the Kirundi interface with fluent speakers, and test voice availability on the devices people use. A real banking integration would require a banking partner and server-verifiable approval for each transfer.

## Testing instructions for judges

- **Hosted demo** — [sauti-hybrid-ai.web.app](https://sauti-hybrid-ai.web.app). Choose English, complete onboarding if prompted, and use **Try the demo**, or sign in with the fictitious demo account `demo@sauti.app` / `Sauti2026`.
- **On-device** — On eligible desktop Chrome, follow the [Firebase setup requirements](https://firebase.google.com/docs/ai-logic/hybrid/web/get-started). Under **Settings → Private on-device AI (Gemini Nano)**, select **Download** if offered and wait for **Ready**. Open the assistant, enter “How much money do I have?”, and check for the balance card and **On-device AI · private** indicator.
- **Cloud** — In an online browser environment where Gemini Nano is unavailable, keep **Use cloud AI (Gemini)** enabled and repeat the same question. Verify the balance result and **Cloud AI** indicator.
- **Offline** — While online, load the dashboard and run the on-device query once. With the app still open, disconnect and repeat the query. Check the cached timestamp. **Basic mode** is the deterministic fallback when the local model cannot answer. Reconnect before trying the transfer.
- **Transfer review** — Ask “Send 20,000 francs to Jean.” Open the draft and review the recipient, amount, and fee. A sandbox transfer can proceed after authentication and an explicit Send action.
- **Accessibility** — Repeat the balance task with the keyboard and the available screen reader. Try high contrast and 200% text size. Record the actual device, browser, and result before citing a manual test.

For an offline-capable local build and detailed recording steps, see the [demo guide](DEMO_GUIDE.md).

## Devpost fields and assets

| Field | Draft answer or asset |
|---|---|
| Entrant type, residence, organization, eligibility statements | Entrant to complete with their actual details |
| Project start date and new or existing | November 15, 2026 based on Git history. Entrant to confirm when the work began. |
| Platform | Web (Chrome) |
| Main technology requirement | Use the Firebase AI Logic explanation above and link the Web bridge. |
| Working demo | [Hosted demo](https://sauti-hybrid-ai.web.app). Verify it in a clean browser on the final build. |
| Testing instructions | Use the judge instructions above. |
| Source and open-source license | [Repository](https://github.com/Jitimay/sauti) and [Apache 2.0 license path](https://github.com/Jitimay/sauti/blob/HEAD/LICENSE). GitHub’s public API reported Apache-2.0 on November 24. Check that the final submission commit is visible before entering. |
| Video | Upload the [demo recording](VIDEO_DESCRIPTION.md) to public YouTube and add its URL. Use English audio or English subtitles and stay within three minutes. |

Capture stills from the exact build shown in the video. Prioritize the local balance card and inference badge, the same result with the cloud badge, the offline timestamp, and the transfer review with Send gated by authentication.

## Readiness

- [ ] Record successful on-device and cloud runs of the same balance query. Capture the browser version, app commit, and inference labels. Earlier repository notes record cloud Gemini and TTS checks. Repeat both paths on the final build.
- [ ] Verify the on-device result and cached balance after disconnecting. Verify keyboard navigation, readable focus, and text scaling on the recorded flow.
- [ ] Ask a person in the target audience to find and explain their demo balance without coaching. Note whether they can tell a saved balance from a current one, where they hesitate, and what you changed in response. Use fictitious data and include only anonymized observations in the entry.
- [ ] Open the demo, repository, license, and video links from a clean browser. Match the hosted build to the documented submission commit and keep the demo available through December 16.
