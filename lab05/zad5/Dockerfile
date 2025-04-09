# Etap 1: Budowanie aplikacji
FROM ubuntu:latest AS builder
RUN apt-get update && apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
WORKDIR /usr/src/app
COPY myapp/ .
RUN npm install && npm run build

# Etap 2: Uruchamianie aplikacji z Nginx
FROM nginx:latest
COPY --from=builder /usr/src/app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

# docker build -t my-node-nginx-app .
# docker run -d -p 80:80 my-node-nginx-app

# FROM ubuntu AS build
# WORKDIR /app
# RUN apt-get update && \
#     apt-get install -y nodejs npm && \
#     apt-get clean && \
#     rm -rf /var/lib/apt/lists/* 
# COPY /app/package*.json ./
# RUN npm install
# COPY /app ./
# RUN npm run build

# FROM nginx:alpine
# COPY --from=build /app/dist /usr/share/nginx/html
# EXPOSE 80
# CMD [ "nginx","-g", "daemon off;" ]