FROM node:alpine

RUN apk update
RUN apk add --no-cache python alpine-sdk git
RUN npm install -g truffle ganache-cli

CMD ash
