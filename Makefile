APPLICATION_NAME ?= hubble
REGION ?= us-east-1

login: 
		aws --profile personal ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com

create_repo:
		aws --profile personal ecr create-repository --repository-name ${APPLICATION_NAME} --image-scanning-configuration scanOnPush=true

build_local:
		docker build --build-arg ALCHEMY_GOERLI_URL=${ALCHEMY_GOERLI_URL} --build-arg HUBBLE_PEERS=${HUBBLE_PEERS} --tag ${APPLICATION_NAME} .

run_local:
		docker run -p 2282:2282 -p 2283:2283 -d ${APPLICATION_NAME}

docker_build_and_run_local: build_local run_local

build:
		docker build --platform linux/amd64 --build-arg ALCHEMY_GOERLI_URL=${ALCHEMY_GOERLI_URL} --build-arg HUBBLE_PEERS=${HUBBLE_PEERS} -t ${APPLICATION_NAME} .

tag:
		docker tag ${APPLICATION_NAME} ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/${APPLICATION_NAME}:latest

push:
		docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/${APPLICATION_NAME}:latest

docker_build_and_push: login build tag push