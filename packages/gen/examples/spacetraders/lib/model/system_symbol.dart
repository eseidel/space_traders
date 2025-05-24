extension type SystemSymbol(String value) {
  SystemSymbol(this.value);

  factory SystemSymbol.fromJson(String json) => SystemSymbol(json);

  String toJson() => value;
}
