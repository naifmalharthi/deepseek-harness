# syntax=docker/dockerfile:1
# DSH Web UI — multi-stage: builder (install + full build) → runtime (node slim)

ARG NODE_VERSION=24
ARG PNPM_VERSION=11.7.0

# ───────────────────────── builder ─────────────────────────
# node:24 (bookworm) يتضمن gcc/g++/make/python3 — إلزامية
# لخطوة build:native-system (flock: C → Node-API v8 via cc).
FROM node:${NODE_VERSION} AS builder
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
ARG DSH_CLIENT_COMMIT_HASH=0000000
ARG DSH_CLIENT_VERSION=0.1.6-alpha.1
ENV DSH_CLIENT_COMMIT_HASH=${DSH_CLIENT_COMMIT_HASH} \
    DSH_CLIENT_VERSION=${DSH_CLIENT_VERSION}
WORKDIR /workspace
RUN corepack enable \
 && corepack prepare pnpm@${PNPM_VERSION} --activate
COPY . .
RUN pnpm install --frozen-lockfile
RUN pnpm run build:official

# ───────────────────────── runtime ─────────────────────────
# pnpm dsh يشغّل source عبر tsx — نُنسخ source + node_modules + مخرجات البناء كاملة.
FROM node:${NODE_VERSION}-slim AS runtime
ENV NODE_ENV=production \
    COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
    DSH_HOME=/home/node/.dsh
WORKDIR /workspace
RUN corepack enable \
 && corepack prepare pnpm@${PNPM_VERSION} --activate
COPY --from=builder /workspace /workspace
# volume يُولَد root:root — node لا يكتب فيه بدون هذا السطر
RUN mkdir -p /home/node/.dsh \
 && chown node:node /home/node/.dsh
# entrypoint: يبذر settings.yaml عند أول تشغيل إن غاب
COPY docker/entrypoint.sh /workspace/docker/entrypoint.sh
# patch: يربط الـ webserver على 0.0.0.0 (شرط الـ port mapping)
COPY docker/dsh-web.docker.patch.yml /workspace/docker/dsh-web.docker.patch.yml
RUN chmod +x /workspace/docker/entrypoint.sh
EXPOSE 3080
USER node
ENTRYPOINT ["/workspace/docker/entrypoint.sh"]
CMD ["pnpm", "dsh", "--profile", "web", "--patch", "/workspace/docker/dsh-web.docker.patch.yml", "--no-open"]
