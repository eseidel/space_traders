extension type ShipComponentIntegrity(double value) {
  ShipComponentIntegrity(this.value);

  factory ShipComponentIntegrity.fromJson(String json) =>
      ShipComponentIntegrity(json);

  String toJson() => value;
}
