[![codecov](https://codecov.io/gh/eseidel/space_gen/graph/badge.svg?token=nOnPSYpPXi)](https://codecov.io/gh/eseidel/space_gen)

# space_gen
Simple, hackable Open API generator for Dart

This is not designed to be a full implementation of OpenAPI.  Currently
just enough to generate beautiful Dart bindings for spacetraders.io.

Patches welcome to expand it to support a wider set of OpenAPI.

NOTE: This readme as written is aspirational.  The code is not yet all working.

## Usage

dart run space_gen

## Values
* Generates good quality, modern Dart code
* Not a complete implementation of OpenAPI
* Generates layered output, which can be used in pieces (TBD)
* Generates testable (and tested) code (TBD)

## Intended Design (TBD)
- Phases
  - Parse OpenAPI
  - Resolve references
  - Render Dart code

## Todo
* Actually make the networking work.
* Implement operator== and hashCode?
* Generate tests. https://github.com/eseidel/space_gen/issues/1
* Figure out if types should be immutable or not.
* Use new-type pattern for all schemas in components.
* Support parameter "in" keyword.

## Advantages over Open API Generator 7.0.0
* Dart 3.0+ only (sound null safety)
* Model code round trips through JSON correctly (TBD)

## Why not just contribute to OpenAPI?

As of August 2023, there are two separate (soon to be combined?) OpenAPI
generators for Dart.  One for package:http and one for package:dio.  I only
ever used the http one and it had lots of bugs.  I looked at fixing them
in OpenAPI, but failed to figure out how to hack on the OpenAPI generator
(Java) or successfully interact with the community (several separate slacks).