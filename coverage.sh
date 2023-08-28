#!/bin/sh -e

# A script for computing combined coverage for all packages in the repo.
# This can be used for viewing coverage locally in your editor.

PACKAGES='cli db server types ui'

dart pub global activate coverage

for PACKAGE_DIR in $PACKAGES
do
    echo $PACKAGE_DIR
    cd packages/$PACKAGE_DIR
    dart pub get
    dart test --coverage=coverage
    dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.dart_tool/package_config.json --report-on=lib --check-ignore
    cd ../..
done

dart pub global run combine_coverage --repo-path .