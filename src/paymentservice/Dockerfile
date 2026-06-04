ARG BUILDPLATFORM=linux/amd64

FROM --platform=$BUILDPLATFORM node:20-alpine AS builder

RUN apk add --no-cache \
    python3 \
    make \
    g++

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm ci --omit=dev

COPY . .

FROM node:20-alpine

WORKDIR /usr/src/app

ENV NODE_ENV=production

COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY . .

USER node

EXPOSE 50051

CMD ["node", "index.js"]