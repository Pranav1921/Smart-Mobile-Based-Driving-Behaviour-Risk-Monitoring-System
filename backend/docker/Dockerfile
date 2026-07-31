FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies first (for caching)
COPY package*.json ./
RUN npm ci

# Copy configuration and source files
COPY tsconfig.json ./
COPY src/ ./src/

# Generate Prisma Client
RUN npx prisma generate --schema=src/prisma/schema.prisma

# Build the TypeScript project
RUN npm run build

# Remove development dependencies
RUN npm prune --production

# --- Production Stage ---
FROM node:20-alpine AS runner

WORKDIR /app

# Copy built app and required run dependencies
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/src/prisma ./src/prisma

# Expose server port
EXPOSE 3000

# Set environment
ENV NODE_ENV=production

# Run the backend server
CMD ["node", "dist/server.js"]
