# Stage 1: Build the Flutter web app
FROM debian:latest AS build-env

# Install Flutter dependencies
RUN apt-get update && \
    apt-get install -y curl git unzip && \
    apt-get clean

# Clone the Flutter repo
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter

# Set Flutter path
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Enable Flutter web
RUN flutter channel stable && \
    flutter upgrade && \
    flutter config --enable-web

# Copy files to container and build
WORKDIR /app
COPY . .
RUN flutter pub get
RUN flutter build web

# Stage 2: Create the run environment
FROM nginx:alpine

# Copy the build output to replace the default nginx contents.
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]