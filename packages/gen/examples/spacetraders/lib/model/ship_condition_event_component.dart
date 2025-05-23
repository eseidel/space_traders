enum ShipConditionEventComponent {
  FRAME._('FRAME'),
  REACTOR._('REACTOR'),
  ENGINE._('ENGINE');

  const ShipConditionEventComponent._(this.value);

  factory ShipConditionEventComponent.fromJson(String json) {
    return ShipConditionEventComponent.values.firstWhere(
      (value) => value.value == json,
      orElse:
          () =>
              throw Exception(
                'Unknown ShipConditionEventComponent value: $json',
              ),
    );
  }

  final String value;

  String toJson() => value;
}
