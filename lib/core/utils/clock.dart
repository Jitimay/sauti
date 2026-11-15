/// Injectable time source for deterministic tests.
abstract interface class Clock {
  DateTime now();
}

final class SystemClock implements Clock {
  const SystemClock();
  @override
  DateTime now() => DateTime.now();
}

final class FixedClock implements Clock {
  FixedClock(this.value);
  DateTime value;
  @override
  DateTime now() => value;
  void advance(Duration d) => value = value.add(d);
}
