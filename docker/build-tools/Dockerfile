FROM debian:jessie

RUN apt-get update \
    && apt-get install -y curl php5-mcrypt php5-cli git \
    && rm -r /var/lib/apt/lists/*

# node setup through nvm
RUN curl https://raw.githubusercontent.com/creationix/nvm/v0.11.1/install.sh | bash \
    && . ~/.profile \
    && nvm install 0.12.8 \
    && echo "nvm use 0.12.8" >> ~/.profile

# Installs actual tools required to build courseadvisor
RUN . ~/.profile && npm install -g gulp \
    && curl -sS https://getcomposer.org/installer | php

VOLUME ["/data/build"]
