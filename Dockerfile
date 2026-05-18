FROM node:20-slim

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 3000

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD curl --fail http://localhost:3000/health || exit 1

CMD ["npm", "start"]
