FROM ghcr.io/cirruslabs/flutter:latest AS build-env

# Copy files to container and build
RUN mkdir /app/
COPY . /app/
WORKDIR /app/
RUN /bin/sh -c flutter build web

# use nginx to deploy
FROM nginx:1.25.2-alpine

# copy the info of the builded web app to nginx
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Expose and run nginx
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
