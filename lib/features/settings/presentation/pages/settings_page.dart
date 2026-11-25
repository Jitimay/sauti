import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sauti_hybrid_ai/sauti_hybrid_ai.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
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
      (b) => (
        name: b.state.user?.displayName ?? '',
        email: b.state.user?.email ?? '',
      ),
    );
    final prefs = context.watch<PreferencesCubit>().state;
    final cloudAvailable = config.isFirebaseConfigured;
    final status = StatusColors.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Semantics(header: true, child: Text(l.settingsTitle)),
      ),
      body: ResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            if (user.name.isNotEmpty || user.email.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      InitialsAvatar(user.name, size: 52),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (user.name.isNotEmpty)
                              Text(user.name, style: text.titleMedium),
                            if (user.email.isNotEmpty)
                              Text(user.email, style: text.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Card(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.language_rounded,
                    iconColor: AppColors.blue,
                    title: l.languageSetting,
                    subtitle: prefs.language.nativeName,
                    onTap: () =>
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const LanguagePage(popOnSelect: true),
                          ),
                        ),
                  ),
                  const Divider(indent: 56, endIndent: 16, height: 1),
                  _SettingsTile(
                    icon: Icons.accessibility_new_rounded,
                    iconColor: AppColors.blue,
                    title: l.accessibilitySetting,
                    subtitle: l.highContrastDescription,
                    onTap: () => context.push(Routes.accessibility),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const IconBubble(Icons.cloud_outlined, size: 40),
                    title: Text(l.cloudAiSetting),
                    subtitle: Text(
                      cloudAvailable
                          ? l.cloudAiDescription
                          : l.cloudAiNotConfigured,
                    ),
                    isThreeLine: true,
                    value: cloudAvailable && prefs.cloudAiEnabled,
                    onChanged: cloudAvailable
                        ? (v) => context.read<PreferencesCubit>().setCloudAi(v)
                        : null,
                  ),
                  if (cloudAvailable) ...[
                    const Divider(indent: 18, endIndent: 18, height: 1),
                    SwitchListTile(
                      secondary: const IconBubble(
                        Icons.record_voice_over_rounded,
                        size: 40,
                      ),
                      title: Text(l.naturalVoiceSetting),
                      subtitle: Text(l.naturalVoiceDescription),
                      isThreeLine: true,
                      value: prefs.cloudAiEnabled && prefs.naturalVoiceEnabled,
                      onChanged: prefs.cloudAiEnabled
                          ? (v) => context
                                .read<PreferencesCubit>()
                                .setNaturalVoice(v)
                          : null,
                    ),
                  ],
                  if (sl.isRegistered<HybridAiClient>()) ...[
                    const Divider(indent: 18, endIndent: 18, height: 1),
                    OnDeviceAiTile(client: sl<HybridAiClient>()),
                  ],
                ],
              ),
            ),
            if (config.isDemo) ...[
              const SizedBox(height: 12),
              SectionHeader(l.demoControls),
              Card(child: _SimulateOfflineTile()),
            ],
            const SizedBox(height: 12),
            SectionHeader(l.aboutSection),
            Card(
              child: ListTile(
                leading: const IconBubble(Icons.info_outline_rounded, size: 40),
                title: Text(
                  config.isDemo ? l.environmentDemo : l.environmentLive,
                ),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: status.error,
                side: BorderSide(color: status.error),
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: Text(l.signOut),
              onPressed: () =>
                  context.read<AuthBloc>().add(const SignOutRequested()),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = StatusColors.of(context);

    return ListTile(
      leading: IconBubble(
        icon,
        size: 40,
        color: status.isHighContrast ? status.accent : iconColor,
      ),
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: Icon(Icons.chevron_right_rounded, color: status.muted),
      minTileHeight: 64,
      onTap: onTap,
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
      secondary: const IconBubble(Icons.cloud_off_rounded, size: 40),
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
        leading: IconBubble(
          state == OnDeviceState.available
              ? Icons.lock_rounded
              : Icons.phone_android_rounded,
          size: 40,
          color: state == OnDeviceState.available
              ? StatusColors.of(context).success
              : null,
          background: state == OnDeviceState.available
              ? StatusColors.of(context).successBg
              : null,
        ),
        title: Text(l.onDeviceAiSetting),
        subtitle: Text(subtitle),
        isThreeLine: true,
        trailing: switch (state) {
          OnDeviceState.downloadable => FilledButton(
            onPressed: _download,
            child: Text(l.onDeviceAiDownload),
          ),
          OnDeviceState.downloading || null => const SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          OnDeviceState.available => Icon(
            Icons.check_circle_rounded,
            color: StatusColors.of(context).success,
          ),
          OnDeviceState.unavailable => null,
        },
      ),
    );
  }
}
