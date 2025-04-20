# An example of using a custom Dockerfile with Dart Frog
# Official Dart image: https://hub.docker.com/_/dart
# Specify the Dart SDK base image version using dart:<version> (ex: dart:2.17)
FROM dart:stable AS build

# Install dart_frog_cli before copying sources to avoid re-installing each time.
RUN dart pub global activate dart_frog_cli

# Copy over only the packages we need.
WORKDIR /app
# cli should split into two parts, and server only depend on the bottom one.
COPY cli ./cli/
COPY db ./db/
COPY openapi ./openapi/
COPY protocol ./protocol/
COPY server ./server/
COPY types ./types/

# Resolve app dependencies.
WORKDIR /app/server
RUN dart pub get

# Generate a production build.
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