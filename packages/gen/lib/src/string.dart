// Convert CamelCase to snake_case
String snakeFromCamel(String camel) {
  final snake = camel.splitMapJoin(
    RegExp('[A-Z]'),
    onMatch: (m) => '_${m.group(0)}'.toLowerCase(),
    onNonMatch: (n) => n.toLowerCase(),
  );
  return snake.startsWith('_') ? snake.substring(1) : snake;
}

/// Convert snake_case to CamelCase.
String camelFromSnake(String snake) {
  return snake.splitMapJoin(
    RegExp('_'),
    onMatch: (m) => '',
    onNonMatch: (n) => n.capitalize(),
  );
}

String lowercaseCamelFromSnake(String snake) {
  final camel = camelFromSnake(snake);
  return camel[0].toLowerCase() + camel.substring(1);
}

/// Convert kebab-case to snake_case.
String snakeFromKebab(String kebab) => kebab.replaceAll('-', '_');

/// Converts from SCREAMING_CAPS to camelCase.
String camelFromScreamingCaps(String caps) {
  final camel = caps.splitMapJoin(
    RegExp('_'),
    onMatch: (m) => '',
    onNonMatch: (n) => n.toLowerCase().capitalize(),
  );
  return camel[0].toLowerCase() + camel.substring(1);
}

bool isReservedWord(String word) {
  const reservedWords = {
    'void',
    'int',
    'double',
    'num',
    'bool',
    'dynamic',
    'yield',
    'required',
  };
  return reservedWords.contains(word);
}

extension CapitalizeString on String {
  String capitalize() {
    if (isEmpty) {
      return this;
    }
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
