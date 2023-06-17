FROM dart:stable AS build

# Copy files to container and build
WORKDIR /app
COPY . .

WORKDIR /app/packages/space_traders_cli

# pubspec.lock should ensure this pulls the same as locally.
# Would be nice to have a mechanism to ensure that with checksums, etc.
RUN dart pub get
RUN dart compile exe bin/space_traders_cli.dart -o /app/serve

# Build minimal serving image from AOT-compiled `/server`
# and the pre-built AOT-runtime in the `/runtime/` directory of the base image.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/serve /app/backend/

CMD ["/app/backend/serve"]