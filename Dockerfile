# Use a Node.js base image
FROM node:18.7.0

# Install curl
RUN apt-get update && apt-get install -y curl

# Install yarn and pm2
RUN npm install -g pm2

# Install pm2-logrotate
RUN pm2 install pm2-logrotate

# Set the working directory
WORKDIR /app

# Clone the code repository
RUN git clone https://github.com/farcasterxyz/hubble.git .

# Checkout the stable release
RUN git checkout @farcaster/hubble@1.2.0

# Build hubble
RUN yarn install && yarn build

COPY start.sh /app/apps/hubble/start.sh
RUN chmod +x /app/apps/hubble/start.sh

# Create an identity
RUN cd apps/hubble/ && yarn identity create

# Expose the required ports
EXPOSE 2282

ARG ALCHEMY_GOERLI_URL
ENV ALCHEMY_GOERLI_URL=$ALCHEMY_GOERLI_URL

ARG HUBBLE_PEERS
ENV HUBBLE_PEERS=$HUBBLE_PEERS

WORKDIR /app/apps/hubble

# Set the command to run when the container starts
CMD ["sh", "-c", "/app/apps/hubble/start.sh"]
