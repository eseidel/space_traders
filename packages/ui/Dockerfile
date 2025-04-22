FROM ghcr.io/cirruslabs/flutter:latest AS build-env

# Disable "don't run as root" warning in flutter.
ENV BOT=true

# Precache Web SDK to avoid re-downloading every time source code changes.
RUN flutter precache --web

# Resolve app dependencies.
WORKDIR /app
COPY client/ ./client/
COPY openapi/ ./openapi/
COPY protocol/ ./protocol/
COPY types/ ./types/
COPY ui/ ./ui/

# Pull network dependencies from pub.
WORKDIR /app/ui
RUN flutter pub get

RUN flutter build web

# use nginx to deploy
FROM nginx:alpine

# Copy the nginx config
COPY ui/nginx.conf /etc/nginx/conf.d/default.conf

# copy the info of the builded web app to nginx
COPY --from=build-env /app/ui/build/web /usr/share/nginx/html

# Expose and run nginx
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
