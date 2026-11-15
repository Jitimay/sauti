import 'package:equatable/equatable.dart';

enum DataSource { live, cached }

/// Wraps data with its provenance so the UI and agent can always tell users
/// whether information is live or a cached copy.
final class Fresh<T> extends Equatable {
  const Fresh(this.data, {required this.source, required this.asOf});

  const Fresh.live(this.data, this.asOf) : source = DataSource.live;

  final T data;
  final DataSource source;
  final DateTime asOf;

  bool get isCached => source == DataSource.cached;

  Fresh<R> map<R>(R Function(T) f) => Fresh(f(data), source: source, asOf: asOf);

  @override
  List<Object?> get props => [data, source, asOf];
}
