FROM node:10-alpine

MAINTAINER OmiseGO Engineering <eng@omise.co>

WORKDIR /home/node

RUN apk add --update \
    python \
    python-dev \
    py-pip \
    build-base \
		git


RUN git clone -b v2.0.0 https://github.com/omisego/plasma-contracts.git 
RUN cd /home/node/plasma-contracts/plasma_framework && npm install
