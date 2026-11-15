/// Abstraction over connectivity so domain/data code can react to offline
/// state without depending on a plugin.
abstract interface class NetworkStatus {
  Future<bool> isOnline();
  Stream<bool> watch();
}
