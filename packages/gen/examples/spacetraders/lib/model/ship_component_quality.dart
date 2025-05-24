extension type ShipComponentQuality(double value) {
  ShipComponentQuality(this.value);

  factory ShipComponentQuality.fromJson(String json) =>
      ShipComponentQuality(json);

  String toJson() => value;
}
