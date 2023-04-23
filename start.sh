#!/bin/bash

pm2-runtime start "yarn start -e ${ALCHEMY_GOERLI_URL} -b ${HUBBLE_PEERS} -n 2" --name hubble
