FROM node:20-alpine
WORKDIR /app

# Install dependencies first so Docker can cache this layer
COPY package*.json ./
RUN npm ci --omit=dev

# Copy the application code (including uploads/ and seed/)
COPY . .

# Let the non-root "node" user write uploaded images
RUN chown -R node:node /app
USER node

ENV NODE_ENV=production
EXPOSE 4000
CMD ["node", "server.js"]
