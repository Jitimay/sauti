import 'package:flutter/foundation.dart';

import '../sauti_hybrid_ai.dart';

/// iOS and Android use the method-channel bridge; other platforms have no
/// hybrid path yet.
HybridAiClient? createPlatformClient() => switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.android => SautiHybridAi(),
      _ => null,
    };
