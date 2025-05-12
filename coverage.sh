#!/bin/sh -e

# A script for computing combined coverage for all packages in the repo.
# This can be used for viewing coverage locally in your editor.

# No ui tests yet, so not testing ui package.
PACKAGES='cli client db gen protocol server types'

dart pub global activate coverage
dart pub global activate combine_coverage

for PACKAGE_DIR in $PACKAGES
do
    echo $PACKAGE_DIR
    cd packages/$PACKAGE_DIR
    dart pub get
    dart test --coverage=coverage
    # --report-on is wanted to exclude openapi generated code from coverage.
    dart pub global run coverage:format_coverage --lcov --in=coverage \
        --out=coverage/lcov.info --packages=.dart_tool/package_config.json \
        --report-on=../cli/lib/ \
        --report-on=../db/lib/ \
        --report-on=../server/lib/ \
        --report-on=../types/lib/ \
        --check-ignore
    cd ../..
done

dart pub global run combine_coverage --repo-path .