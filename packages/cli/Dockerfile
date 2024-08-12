# This is expected to be invoked with /packages as the context.
# Example:
# cd packages
# docker build -t cli -f cli/Dockerfile .
FROM dart:stable AS build
ARG BIN=cli

# Resolve app dependencies.
WORKDIR /app
COPY openapi/pubspec.* ./openapi/
COPY types/pubspec.* ./types/
COPY db/pubspec.* ./db/
COPY cli/pubspec.* ./cli/
WORKDIR /app/cli
RUN dart pub get

# Copy all packages and build them.
WORKDIR /app
COPY . .

WORKDIR /app/cli
RUN dart pub get --offline

RUN mkdir -p /app/bin
RUN dart compile exe -DPGHOST=db bin/${BIN}.dart -o /app/bin/server

# Build minimal serving image from AOT-compiled `/server` and required system
# libraries and configuration files stored in `/runtime/` from the build stage.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/

CMD ["/app/bin/server"]