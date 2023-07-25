#!/bin/sh -xe
dart test --coverage=../../coverage 
dart pub global activate coverage
$HOME/.pub-cache/bin/format_coverage --lcov --in=../../coverage \
    --out=../../coverage/lcov.info --report-on=lib