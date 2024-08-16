# An example of using a custom Dockerfile with Dart Frog
# Official Dart image: https://hub.docker.com/_/dart
# Specify the Dart SDK base image version using dart:<version> (ex: dart:2.17)
FROM dart:stable AS build

# Resolve app dependencies.
WORKDIR /app
COPY openapi/pubspec.* ./openapi/
COPY types/pubspec.* ./types/
COPY db/pubspec.* ./db/
COPY server/pubspec.* ./server/
WORKDIR /app/server
RUN dart pub get

# Copy all packages and build them.
WORKDIR /app
COPY . .
WORKDIR /app/server

# Generate a production build.
RUN dart pub global activate dart_frog_cli
RUN dart pub global run dart_frog_cli:dart_frog build

# Ensure packages are still up-to-date if anything has changed.
RUN dart pub get --offline
RUN dart compile exe -DPGHOST=db build/bin/server.dart -o build/bin/server

# Build minimal serving image from AOT-compiled `/server` and required system
# libraries and configuration files stored in `/runtime/` from the build stage.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/server/build/bin/server /app/bin/
# Uncomment the following line if you are serving static files.
# COPY --from=build /app/server/build/public /public/

# Start the server.
CMD ["/app/bin/server"]