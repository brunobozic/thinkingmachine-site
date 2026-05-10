# syntax=docker/dockerfile:1.7

# ---------- Stage 1: Build ----------
# Pinned by digest for supply-chain protection. To bump:
#   docker pull node:20-alpine && docker inspect --format='{{index .RepoDigests 0}}' node:20-alpine
FROM node:26-alpine@sha256:e71ac5e964b9201072425d59d2e876359efa25dc96bb1768cb73295728d6e4ea AS builder
WORKDIR /app

# Install deps with cache-friendly layering
COPY package.json package-lock.json* ./
RUN npm install --no-audit --no-fund

# Copy sources and build
COPY . .
RUN npm run build

# ---------- Stage 2: Serve ----------
# Pinned by digest. Same bump procedure as above.
FROM nginx:1.27-alpine@sha256:65645c7bb6a0661892a8b03b89d0743208a18dd2f3f17a54ef4b76fb8e2f2a10 AS runner

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
