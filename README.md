# farcaster-hub

# Welcome

These instructions will help you setup a Farcaster hub either on testnet or mainnet. They are based on [these instructions](https://warpcast.notion.site/Set-up-Hubble-on-EC2-Public-23b4e81d8f604ca9bf8b68f4bb086042) from Merkle

NOTE: This hub uses the suggested EC2 resource allocation. It will cost ~$100/month!

Each step has a Makefile-based version (simpler) or the equivalent manual commands

# 0. Initial setup

1. [Install docker](https://docs.docker.com/install/) and start the Docker daemon (by opening Docker Desktop)
2. [Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
3. Make sure you have the AWS CLI installed on your machine. You can check by running `aws --version`. Make sure you have a profile setup by running `aws configure`
4. Clone this repo: `git clone https://github.com/bitwise-invest/farcaster-hub.git` and enter the folder `cd farcaster-hub`

# 1. Run Hub Locally (optional - the Merkle instructions don't talk about running locally)

```
make docker_build_and_run_local
```

If you want, you can execute these [manually](#run-locally---manual-commands)

# 2. Export Local Variables

```
export ALCHEMY_GOERLI_URL={INSERT_ALCHEMY_URL}
export AWS_ACCOUNT_ID={INSERT_AWS_ACCOUNT_ID}
export AWS_REGION={INSERT_REGION} // Example region is "us-west-1"
```

If you want to run testnet:
```
export HUBBLE_PEERS=/dns/testnet1.farcaster.xyz/tcp/2282
```
or mainnet:
```
export HUBBLE_PEERS=/dns/hoyt.farcaster.xyz/tcp/2282
```

NOTE: To move to mainnet, you'll want to run through these instructions for testnet first and make sure you're syncing. Read this before trying mainnet: https://warpcast.notion.site/warpcast/Mainnet-Hubs-dc2ff6d528f64992afe03797b61dec32

# 3. Push Docker Image to ECR

## Create ECR repo (FIRST TIME ONLY):

```
make login && make create_repo
```

If you want, you can execute these [manually](#create-ecr-repo---manual-commands)

## Push to ECR Repo:

```
make docker_build_and_push
```

If you want, you can execute these [manually](#push-docker-image-to-ecr---manual-commands)

# 4. Terraform infra on AWS:

1. In `variables.tf`, set the "key_name" to your `key_name.pem` file (or [create a new one](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/create-key-pairs.html))

2. 
```
terraform init
```
3. Plan: dry-run that will show you what AWS changes will be made
```
terraform plan
```
4. Apply: actually makes the AWS changes
```
terraform apply
```

To destroy:

```
terraform destroy
```

# 5. PROFIT

That's it! After a few minutes, you should have a hub running on an EC2 instance in AWS. You can see the logs by:

1. SSH into the instance. You can do this using your pem file by running `ssh ubuntu@{IP_ADDRESS_OF_INSTANCE} -i /path/to/key/file.pem` or clicking "Connect" on the EC2 console
2. Wait a few minutes for the process to start and then list docker containers. You'll have to use the root user because docker was installed as root: `sudo docker ps` 
3. Enter container: `sudo docker exec -it {DOCKER_CONTAINER_ID} /bin/bash`
4. List running pm2 processes: `pm2 ls`
5. Show logs: `pm2 logs`

You can check that everything is working by running the script in Step 2 of the [Running a Testhub docs](https://warpcast.notion.site/Running-a-testnet-hub-on-Linux-Public-9d8ac91f142c48a58b6926d69045afdb).

---

# Additional Docker Setup or Debugging Commands

- Build docker images: `docker build . -t hubble`
- Run docker image: `docker run -p 2282:2282 -p 2283:2283 -d hubble`
- Debugging
  - List containers (with container id) - `docker ps`
  - Show logs - `docker logs [container id]`
- To enter the machine: `docker exec -it [container id] /bin/bash`
  - If you need to exit, command is `cmd+z` I believe
- Kill docker image: `docker kill [container id]`

---

# Manual instructions

## Run locally - manual commands

1. 
```
docker build --build-arg ALCHEMY_GOERLI_URL=$ALCHEMY_GOERLI_URL --build-arg HUBBLE_PEERS=$HUBBLE_PEERS -t hubble .
docker run -p 2282:2282 -p 2283:2283 -d hubble
```

## Create ECR repo - manual commands

1. Authenticate
```
aws --profile personal ecr get-login-password  --region us-east-1 | docker login --username AWS --password-stdin $$AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```
2. Create ECR repository 
```
aws --profile personal ecr create-repository --repository-name hubble --image-scanning-configuration scanOnPush=true
```

##  Push Docker Image to ECR - manual commands

1. Authenticate
```
aws --profile personal ecr get-login-password  --region us-east-1 | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```

2. Build
```
docker build --platform linux/amd64 --build-arg ALCHEMY_GOERLI_URL=$ALCHEMY_GOERLI_URL -t hubble .
```

3. Tag
```
docker tag hubble $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/hubble:latest
```
4. Push
```
docker push $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/hubble:latest
```