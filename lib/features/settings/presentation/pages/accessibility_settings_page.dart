import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/widgets/layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/settings.dart';
import '../bloc/accessibility_bloc.dart';

/// All controls are standard switches/sliders/segmented buttons with
/// labels — operable by touch, switch access, keyboard and screen readers.
class AccessibilitySettingsPage extends StatelessWidget {
  const AccessibilitySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.watch<AccessibilityBloc>().state;
    final bloc = context.read<AccessibilityBloc>();
    final scales = AccessibilitySettings.textScales;
    final idx = scales.indexWhere((v) => (v - s.textScale).abs() < 0.01).clamp(0, scales.length - 1);
    final percent = (s.textScale * 100).round();

    return Scaffold(
      appBar: AppBar(title: Text(l.accessibilityTitle)),
      body: ResponsiveBody(
        child: ListView(children: [
          SectionHeader(l.textSize),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  IconButton.outlined(
                    tooltip: '${l.textSize} −',
                    onPressed: idx == 0 ? null : () => bloc.add(FontSizeChanged(scales[idx - 1])),
                    icon: const Icon(Icons.text_decrease_rounded),
                  ),
                  Expanded(
                    child: Slider(
                      value: idx.toDouble(),
                      min: 0,
                      max: (scales.length - 1).toDouble(),
                      divisions: scales.length - 1,
                      label: l.textSizeValue(percent),
                      semanticFormatterCallback: (_) => l.textSizeValue(percent),
                      onChanged: (v) => bloc.add(FontSizeChanged(scales[v.round()])),
                    ),
                  ),
                  IconButton.outlined(
                    tooltip: '${l.textSize} +',
                    onPressed: idx == scales.length - 1 ? null : () => bloc.add(FontSizeChanged(scales[idx + 1])),
                    icon: const Icon(Icons.text_increase_rounded),
                  ),
                ]),
                Center(child: Text(l.textSizeValue(percent), style: Theme.of(context).textTheme.titleMedium)),
                const Divider(height: 24),
                Text(l.previewText, style: Theme.of(context).textTheme.bodyLarge),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(children: [
              SwitchListTile(
                secondary: const IconBubble(Icons.contrast_rounded, size: 42),
                title: Text(l.highContrast),
                subtitle: Text(l.highContrastDescription),
                value: s.highContrast,
                onChanged: (v) => bloc.add(HighContrastChanged(v)),
              ),
              const Divider(indent: 18, endIndent: 18),
              SwitchListTile(
                secondary: const IconBubble(Icons.view_agenda_outlined, size: 42),
                title: Text(l.simplifiedMode),
                subtitle: Text(l.simplifiedModeDescription),
                value: s.interactionMode == InteractionMode.simplified,
                onChanged: (v) => bloc.add(InteractionModeChanged(v ? InteractionMode.simplified : InteractionMode.standard)),
              ),
              const Divider(indent: 18, endIndent: 18),
              SwitchListTile(
                secondary: const IconBubble(Icons.motion_photos_off_outlined, size: 42),
                title: Text(l.reduceMotion),
                value: s.reduceMotion,
                onChanged: (v) => bloc.add(ReduceMotionChanged(v)),
              ),
            ]),
          ),
          SectionHeader(l.voiceFeedback),
          Card(
            child: Column(children: [
              SwitchListTile(
                secondary: const IconBubble(Icons.record_voice_over_outlined, size: 42),
                title: Text(l.voiceFeedback),
                value: s.voiceFeedback,
                onChanged: (v) => bloc.add(VoiceFeedbackChanged(v)),
              ),
              const Divider(indent: 18, endIndent: 18),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.speechSpeed, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<double>(
                    segments: [
                      ButtonSegment(value: 0.3, label: Text(l.speechSlow)),
                      ButtonSegment(value: 0.5, label: Text(l.speechNormal)),
                      ButtonSegment(value: 0.75, label: Text(l.speechFast)),
                    ],
                    selected: {
                      s.speechRate <= 0.4 ? 0.3 : (s.speechRate >= 0.65 ? 0.75 : 0.5),
                    },
                    onSelectionChanged: (v) => bloc.add(SpeechRateChanged(v.first)),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}
