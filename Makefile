APPLICATION_NAME ?= hubble

login: 
		aws ecr get-login-password --AWS_REGION ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

create_repo:
		aws ecr create-repository --AWS_REGION ${AWS_REGION} --repository-name ${APPLICATION_NAME} --image-scanning-configuration scanOnPush=true

build_local:
		docker build --build-arg ALCHEMY_GOERLI_URL=${ALCHEMY_GOERLI_URL} --build-arg HUBBLE_PEERS=${HUBBLE_PEERS} --tag ${APPLICATION_NAME} .

run_local:
		docker run -p 2282:2282 -p 2283:2283 -d ${APPLICATION_NAME}

docker_build_and_run_local: build_local run_local

build:
		docker build --platform linux/amd64 --build-arg ALCHEMY_GOERLI_URL=${ALCHEMY_GOERLI_URL} --build-arg HUBBLE_PEERS=${HUBBLE_PEERS} -t ${APPLICATION_NAME} .

tag:
		docker tag ${APPLICATION_NAME} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${APPLICATION_NAME}:latest

push:
		docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${APPLICATION_NAME}:latest

docker_build_and_push: login build tag push
