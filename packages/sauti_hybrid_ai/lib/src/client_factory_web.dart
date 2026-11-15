import '../sauti_hybrid_ai.dart';
import 'web_hybrid_ai.dart';

/// On the web, hybrid inference goes through the Firebase AI Logic JS SDK.
HybridAiClient? createPlatformClient() => WebHybridAi();
