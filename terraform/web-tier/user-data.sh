#!/bin/bash
# Boot script for the web servers in the Auto Scaling Group.
# Installs Docker, fetches the settings from Parameter Store, pulls the
# images from ECR and starts the frontend and backend containers.
set -euxo pipefail
exec > >(tee /var/log/web-boot.log) 2>&1

REGION=ap-south-1
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y ca-certificates curl unzip

# Docker
curl -fsSL https://get.docker.com | sh
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<'EOT'
{ "log-driver": "json-file", "log-opts": { "max-size": "10m", "max-file": "3" } }
EOT
systemctl restart docker

# AWS CLI v2
curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install

# Settings from the encrypted parameter
mkdir -p /opt/food-web
cd /opt/food-web
aws ssm get-parameter --region "$REGION" --name /food/backend_env \
  --with-decryption --query Parameter.Value --output text > backend.env
chmod 600 backend.env

# Log in to ECR
ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com"
aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"

# Compose file for the web tier (frontend + backend only)
cat > docker-compose.yml <<EOT
services:
  backend:
    image: ${REGISTRY}/food-backend:latest
    restart: unless-stopped
    env_file: ./backend.env
    healthcheck:
      test: ["CMD", "node", "-e", "fetch('http://localhost:4000/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 15s
  frontend:
    image: ${REGISTRY}/food-frontend:latest
    restart: unless-stopped
    ports:
      - "80:80"
    depends_on:
      backend:
        condition: service_healthy
EOT

docker compose pull
docker compose up -d
docker compose ps
