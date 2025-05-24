extension type WaypointSymbol(String value) {
  WaypointSymbol(this.value);

  factory WaypointSymbol.fromJson(String json) => WaypointSymbol(json);

  String toJson() => value;
}
