# Dockerfile for BD_MART Backend
# =============================
# Multi-stage build for optimal production image
# --------------------------------------------
# Phase 1: Build stage
# Phase 2: Production stage
# --------------------------------------------

# --------------------------------------------
# Phase 1: Build Stage
# --------------------------------------------
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Install dependencies first (layer caching)
COPY package*.json ./

# Install all dependencies including devDependencies
RUN npm install

# Copy source code
COPY . .

# Generate TypeScript types if needed (optional)
# RUN npx tsc

# --------------------------------------------
# Phase 2: Production Stage
# --------------------------------------------
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Create non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy package.json and install only production dependencies
COPY package*.json ./
RUN npm install --only=production

# Copy compiled source code from builder stage
COPY --from=builder /app/dist ./dist  # If using TypeScript
COPY --from=builder /app/src ./src    # If using JS directly

# Set ownership to non-root user
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose the application port
EXPOSE 5000

# Environment variable for Node.js environment
ENV NODE_ENV=production

# Health check for Docker
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:5000/health || exit 1

# Start the application
CMD ["npm", "start"]