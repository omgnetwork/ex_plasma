FROM node:10-alpine

MAINTAINER OmiseGO Engineering <eng@omise.co>

WORKDIR /home/node

RUN apk add --update \
    python \
    python-dev \
    py-pip \
    build-base \
		git

RUN git clone https://github.com/omgnetwork/plasma-contracts.git
RUN cd /home/node/plasma-contracts && git checkout b3a5c8d5232edfab8617f6939733b08b67863c8a
RUN cd /home/node/plasma-contracts/plasma_framework && npm install
