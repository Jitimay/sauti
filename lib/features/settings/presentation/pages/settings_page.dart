import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sauti_hybrid_ai/sauti_hybrid_ai.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/network/demo_network_switch.dart';
import '../../../../core/widgets/layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/pages/language_page.dart';
import '../bloc/preferences_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final config = sl<AppConfig>();
    final user = context.select<AuthBloc, ({String name, String email})>(
        (b) => (name: b.state.user?.displayName ?? '', email: b.state.user?.email ?? ''));
    final prefs = context.watch<PreferencesCubit>().state;
    final cloudAvailable = config.isFirebaseConfigured;

    return Scaffold(
      appBar: AppBar(title: Semantics(header: true, child: Text(l.settingsTitle))),
      body: ResponsiveBody(
        child: ListView(children: [
          SectionHeader(l.profileSection),
          Card(
            child: ListTile(
              leading: CircleAvatar(radius: 24, child: Text(user.name.isEmpty ? '?' : user.name.characters.first)),
              title: Text(user.name, style: Theme.of(context).textTheme.titleMedium),
              subtitle: Text(user.email),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.translate_rounded),
                title: Text(l.languageSetting),
                subtitle: Text(prefs.language.nativeName),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context, rootNavigator: true)
                    .push(MaterialPageRoute<void>(builder: (_) => const LanguagePage(popOnSelect: true))),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.accessibility_new_rounded),
                title: Text(l.accessibilitySetting),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(Routes.accessibility),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.cloud_outlined),
                title: Text(l.cloudAiSetting),
                subtitle: Text(cloudAvailable ? l.cloudAiDescription : l.cloudAiNotConfigured),
                isThreeLine: true,
                value: cloudAvailable && prefs.cloudAiEnabled,
                onChanged: cloudAvailable ? (v) => context.read<PreferencesCubit>().setCloudAi(v) : null,
              ),
              if (sl.isRegistered<HybridAiClient>()) ...[
                const Divider(height: 1),
                OnDeviceAiTile(client: sl<HybridAiClient>()),
              ],
            ]),
          ),
          if (config.isDemo) ...[
            SectionHeader(l.demoControls),
            Card(child: _SimulateOfflineTile()),
          ],
          SectionHeader(l.aboutSection),
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: Text(config.isDemo ? l.environmentDemo : l.environmentLive),
                subtitle: Text('Sauti 0.1.0 · ${l.tagline}'),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout_rounded),
            label: Text(l.signOut),
            onPressed: () => context.read<AuthBloc>().add(const SignOutRequested()),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
}

class _SimulateOfflineTile extends StatefulWidget {
  @override
  State<_SimulateOfflineTile> createState() => _SimulateOfflineTileState();
}

class _SimulateOfflineTileState extends State<_SimulateOfflineTile> {
  final _switch = sl<DemoNetworkSwitch>();

  @override
  Widget build(BuildContext context) => StreamBuilder<bool>(
        stream: _switch.changes,
        initialData: _switch.simulateOffline,
        builder: (context, snap) => SwitchListTile(
          secondary: const Icon(Icons.cloud_off_rounded),
          title: Text(context.l10n.simulateOffline),
          subtitle: Text(context.l10n.simulateOfflineDescription),
          isThreeLine: true,
          value: snap.data ?? false,
          onChanged: _switch.set,
        ),
      );
}

/// State of the on-device model (Gemini Nano / Apple Intelligence) with a
/// one-tap download. The Firebase AI Logic SDKs never download the model by
/// themselves, and Chrome only allows it from a user gesture.
class OnDeviceAiTile extends StatefulWidget {
  const OnDeviceAiTile({super.key, required this.client});
  final HybridAiClient client;

  @override
  State<OnDeviceAiTile> createState() => _OnDeviceAiTileState();
}

class _OnDeviceAiTileState extends State<OnDeviceAiTile> {
  OnDeviceState? _state;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final s = await widget.client.status(languageCode: 'en');
    if (mounted) setState(() => _state = s.onDeviceState);
  }

  Future<void> _download() async {
    setState(() => _state = OnDeviceState.downloading);
    final s = await widget.client.prepareOnDevice();
    if (mounted) setState(() => _state = s);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = _state;
    final subtitle = switch (state) {
      null => '',
      OnDeviceState.available => l.onDeviceAiReady,
      OnDeviceState.downloadable => l.onDeviceAiDownloadable,
      OnDeviceState.downloading => l.onDeviceAiDownloading,
      OnDeviceState.unavailable => l.onDeviceAiUnavailable,
    };
    return Semantics(
      container: true,
      liveRegion: true,
      child: ListTile(
        leading: Icon(state == OnDeviceState.available ? Icons.lock_rounded : Icons.phone_android_rounded),
        title: Text(l.onDeviceAiSetting),
        subtitle: Text(subtitle),
        isThreeLine: true,
        trailing: switch (state) {
          OnDeviceState.downloadable => FilledButton(onPressed: _download, child: Text(l.onDeviceAiDownload)),
          OnDeviceState.downloading || null =>
            const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 3)),
          OnDeviceState.available => const Icon(Icons.check_circle_rounded),
          OnDeviceState.unavailable => null,
        },
      ),
    );
  }
}
