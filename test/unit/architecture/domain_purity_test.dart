import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces Clean Architecture: domain layers depend only on Dart, equatable
/// and other domain/core code — never Flutter, Firebase or plugins.
void main() {
  test('domain layers have no Flutter/Firebase/plugin imports', () {
    final forbidden = RegExp(
        r"import 'package:(flutter|material_ui|cupertino_ui|firebase_|cloud_|speech_to_text|flutter_tts|local_auth|shared_preferences|flutter_secure_storage|connectivity_plus|go_router|get_it)");
    final offenders = <String>[];
    final domainDirs = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<Directory>()
        .where((d) => d.path.endsWith('${Platform.pathSeparator}domain'));
    for (final dir in domainDirs) {
      for (final f in dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
        if (forbidden.hasMatch(f.readAsStringSync())) offenders.add(f.path);
      }
    }
    expect(domainDirs, isNotEmpty);
    expect(offenders, isEmpty, reason: 'Domain files importing infrastructure: $offenders');
  });

  test('presentation never imports Firebase directly', () {
    final offenders = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.contains('${Platform.pathSeparator}presentation${Platform.pathSeparator}'))
        .where((f) => RegExp(r"import 'package:(firebase_|cloud_)").hasMatch(f.readAsStringSync()))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty);
  });

  test('no unrestricted Firestore rules', () {
    final rules = File('firebase/firestore.rules');
    if (!rules.existsSync()) return; // created in phase 7
    expect(rules.readAsStringSync(), isNot(matches(RegExp(r'allow\s+read\s*,\s*write\s*:\s*if\s+true'))));
  });
}
