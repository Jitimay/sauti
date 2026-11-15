import 'package:equatable/equatable.dart';

final class AppUser extends Equatable {
  const AppUser({required this.id, required this.displayName, required this.email, required this.isDemo});

  final String id;
  final String displayName;
  final String email;

  /// True for the simulated demo identity. Drives the persistent DEMO label.
  final bool isDemo;

  String get firstName => displayName.split(' ').first;

  @override
  List<Object?> get props => [id, displayName, email, isDemo];
}
