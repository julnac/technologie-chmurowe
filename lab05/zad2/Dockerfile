FROM node:latest
WORKDIR /usr/src/app
COPY app/ .
RUN npm install
ENV NODE_ENV=test
CMD ["node", "server.js"]

# docker build -t my-node-app .
# docker run -d -p 3000:3000 my-node-app