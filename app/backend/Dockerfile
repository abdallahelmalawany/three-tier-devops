# syntax=docker/dockerfile:1.7
ARG NODE_IMAGE=node:24-alpine

# ---- deps: production dependencies only -------------------------------------
FROM ${NODE_IMAGE} AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts && npm cache clean --force

# ---- test: full dependency set + test run (docker build --target test .) ----
FROM ${NODE_IMAGE} AS test
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts
COPY src ./src
COPY test ./test
RUN npm test

# ---- runtime: minimal image, non-root, no npm/build tooling needed ---------
FROM ${NODE_IMAGE} AS runtime
ENV NODE_ENV=production \
    PORT=3000 \
    DB_SSL_CA_PATH=/etc/ssl/certs/rds-global-bundle.pem
WORKDIR /app

# AWS RDS CA bundle so the API can fully verify the database TLS certificate.
ADD --chmod=444 https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem /etc/ssl/certs/rds-global-bundle.pem

# Remove package managers from the final image (smaller, less attack surface).
RUN rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx \
    /usr/local/lib/node_modules/corepack /usr/local/bin/corepack \
    /opt/yarn* /usr/local/bin/yarn /usr/local/bin/yarnpkg

# Application files stay owned by root and are read-only for the runtime user.
COPY --from=deps /app/node_modules ./node_modules
COPY package.json ./
COPY src ./src

ARG APP_VERSION=dev
ENV APP_VERSION=${APP_VERSION}

# "node" (uid 1000) is the unprivileged user shipped with the official image.
USER node
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- http://127.0.0.1:3000/api/health || exit 1

CMD ["node", "src/server.js"]
