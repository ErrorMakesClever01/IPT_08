# ---- Stage 1: build the React app ----
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# ---- Stage 2: serve the built files with nginx ----
FROM nginx:1.27-alpine
RUN apk add --no-cache apache2-utils && \
    htpasswd -bc /etc/nginx/.htpasswd admin TomatoAdmin@2026
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
