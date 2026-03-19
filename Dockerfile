# Multi-stage build for Next.js 16 + pnpm
FROM docker.fnnas.com/library/node:22-alpine AS builder

# Install pnpm
RUN npm install -g pnpm

WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy source code
COPY . .

# Build the application
# Note: Build-time env vars will be passed at build time
ARG NEXT_PUBLIC_PRIVY_APP_ID
ARG POLY_BUILDER_API_KEY
ARG POLY_BUILDER_SECRET
ARG POLY_BUILDER_PASSPHRASE
ARG NEXT_PUBLIC_POLYGON_RPC_URL

ENV NEXT_PUBLIC_PRIVY_APP_ID=$NEXT_PUBLIC_PRIVY_APP_ID
ENV POLY_BUILDER_API_KEY=$POLY_BUILDER_API_KEY
ENV POLY_BUILDER_SECRET=$POLY_BUILDER_SECRET
ENV POLY_BUILDER_PASSPHRASE=$POLY_BUILDER_PASSPHRASE
ENV NEXT_PUBLIC_POLYGON_RPC_URL=$NEXT_PUBLIC_POLYGON_RPC_URL

RUN pnpm build

# Production stage
FROM docker.fnnas.com/library/node:22-alpine AS runner

WORKDIR /app

# Copy necessary files from builder
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

# Set environment for production
ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

CMD ["node", "server.js"]
