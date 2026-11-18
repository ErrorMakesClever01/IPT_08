pipeline {
    agent { label 'food-agent' }

    environment {
        AWS_REGION  = "ap-south-1"
        ACCOUNT_ID  = "895579567065"
        ECS_CLUSTER = "food-cluster"
    }

    stages {
        stage('Login to Amazon ECR') {
            steps {
                sh '''
                REG=$(printf "%s.dkr.ecr.%://amazonaws.com" "$ACCOUNT_ID" "$AWS_REGION")
                aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$REG"
                '''
            }
        }

        stage('Build & Push to ECR') {
            steps {
                sh '''
                REG=$(printf "%s.dkr.ecr.%://amazonaws.com" "$ACCOUNT_ID" "$AWS_REGION")
                docker build -t "$REG/food-backend:latest" ./backend
                docker build -t "$REG/food-frontend:latest" ./frontend
                docker build -t "$REG/food-admin:latest" ./admin

                docker push "$REG/food-backend:latest"
                docker push "$REG/food-frontend:latest"
                docker push "$REG/food-admin:latest"
                '''
            }
        }

        stage('Deploy to Amazon ECS') {
            steps {
                sh '''
                aws ecs update-service --cluster "$ECS_CLUSTER" --service food-backend-service --force-new-deployment --region "$AWS_REGION"
                aws ecs update-service --cluster "$ECS_CLUSTER" --service food-admin-service --force-new-deployment --region "$AWS_REGION"
                '''
            }
        }
    }
}
