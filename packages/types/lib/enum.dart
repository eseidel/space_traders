/// Lets us order enums by their index.
mixin EnumIndexOrdering<T extends Enum> on Enum implements Comparable<T> {
  @override
  int compareTo(T other) => index.compareTo(other.index);

  /// Returns true if this enum is less than [other].
  bool operator <(T other) => index < other.index;

  /// Returns true if this enum is greater than [other].
  bool operator >(T other) => index > other.index;

  /// Returns true if this enum is greater than or equal to [other].
  bool operator >=(T other) => index >= other.index;

  /// Returns true if this enum is less than or equal to [other].
  bool operator <=(T other) => index <= other.index;
}
