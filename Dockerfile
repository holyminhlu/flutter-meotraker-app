# Multi-stage: Flutter web build → Nginx static serve (Render Web Service / Docker)
# Build arg: API_BASE_URL trỏ tới backend đã deploy.

# ---------- Build ----------
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app
COPY mobile/pubspec.yaml mobile/pubspec.lock ./
RUN flutter pub get

COPY mobile/ ./
ARG API_BASE_URL=http://localhost:3000
RUN flutter build web --release \
    --dart-define=API_BASE_URL=${API_BASE_URL}

# ---------- Runtime ----------
FROM nginx:1.27-alpine

# Render injects PORT; official nginx image runs envsubst on templates/*.template
ENV PORT=80
# Chỉ thay ${PORT}, không đụng $uri / $host của nginx
ENV NGINX_ENVSUBST_FILTER=PORT
COPY deploy/nginx.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
