FROM ghcr.io/cirruslabs/flutter:latest AS build-env

# Resolve app dependencies.
WORKDIR /app
COPY openapi/pubspec.* ./openapi/
COPY types/pubspec.* ./types/
COPY ui/pubspec.* ./ui/
WORKDIR /app/ui
RUN flutter pub get

# Copy all packages and build them.
WORKDIR /app
COPY . .

WORKDIR /app/ui
RUN flutter pub get --offline
RUN flutter build web

# use nginx to deploy
FROM nginx:1.25.2-alpine

# copy the info of the builded web app to nginx
COPY --from=build-env /app/ui/build/web /usr/share/nginx/html

# Expose and run nginx
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
