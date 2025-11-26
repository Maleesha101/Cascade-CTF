# MEDUSA 2.0 Challenge: Cascade
# Multi-stage build to minimize image size

FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:18-alpine
WORKDIR /app

# Note: node:18-alpine already has user/group with UID/GID 1000 (node)
# We'll use the existing node user instead of creating a new one

# Copy built dependencies
COPY --from=builder /app/node_modules ./node_modules
COPY app.js internal-service.js ./
COPY package.json ./

# Set ownership of app files
RUN chown -R 1000:1000 /app

# Create startup script to initialize flag at runtime
RUN echo '#!/bin/sh' > /app/init.sh && \
    echo 'echo "MEDUSA2{s0_m4ny_l4y3r5_t0_peel_b4ck}" > /tmp/flag.txt' >> /app/init.sh && \
    echo 'chmod 440 /tmp/flag.txt' >> /app/init.sh && \
    echo 'chown 1000:1000 /tmp/flag.txt 2>/dev/null || true' >> /app/init.sh && \
    echo 'exec npm run start:all' >> /app/init.sh && \
    chmod +x /app/init.sh

# Switch to non-root user
USER 1000:1000

# Expose ports (main app and internal service)
EXPOSE 3000 3001

# Health check
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1))"

# Start both services using init script that creates flag at runtime
CMD ["/app/init.sh"]