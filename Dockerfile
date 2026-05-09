# syntax=docker/dockerfile:1.7

# ---------- Stage 1: Build ----------
FROM node:20-alpine AS builder
WORKDIR /app

# Install deps with cache-friendly layering
COPY package.json package-lock.json* ./
RUN npm ci --no-audit --no-fund

# Copy sources and build
COPY . .
RUN npm run build

# ---------- Stage 2: Serve ----------
FROM nginx:1.27-alpine AS runner

# Drop default nginx config and use ours
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/nginx.conf

# Copy static output
COPY --from=builder /app/dist /usr/share/nginx/html

# Health check (nginx serves a 200 on root once running)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q --spider http://127.0.0.1/ || exit 1

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
