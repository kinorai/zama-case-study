FROM node:24-slim AS base
WORKDIR /app

FROM base AS deps
COPY package.json package-lock.json* .npmrc* ./
RUN npm ci --ignore-scripts --no-audit --no-fund

FROM deps AS build
COPY tsconfig.json ./
COPY src ./src
RUN npm run build
RUN npm prune --omit=dev

FROM gcr.io/distroless/nodejs24-debian12 AS runtime
ENV NODE_ENV=production
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY package.json ./package.json
COPY --from=build /app/dist ./dist
EXPOSE 3000
CMD ["/app/dist/server.js"]
