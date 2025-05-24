extension type ShipComponentCondition(double value) {
  ShipComponentCondition(this.value);

  factory ShipComponentCondition.fromJson(String json) =>
      ShipComponentCondition(json);

  String toJson() => value;
}
