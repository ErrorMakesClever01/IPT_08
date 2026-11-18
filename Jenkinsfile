pipeline {
    agent { label 'food-agent' }

    environment {
        AWS_REGION   = "ap-south-1"
        ECR_REGISTRY = "://amazonaws.com"
        ECS_CLUSTER  = "food-cluster"
    }

    stages {
        stage('Login to Amazon ECR') {
            steps {
                sh """
                aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                """
            }
        }

        stage('Build & Push to ECR') {
            steps {
                sh """
                docker build -t ${ECR_REGISTRY}/food-backend:latest ./backend
                docker build -t ${ECR_REGISTRY}/food-frontend:latest ./frontend
                docker build -t ${ECR_REGISTRY}/food-admin:latest ./admin

                docker push ${ECR_REGISTRY}/food-backend:latest
                docker push ${ECR_REGISTRY}/food-frontend:latest
                docker push ${ECR_REGISTRY}/food-admin:latest
                """
            }
        }

        stage('Deploy to Amazon ECS') {
            steps {
                sh """
                aws ecs update-service --cluster ${ECS_CLUSTER} --service food-backend-service --force-new-deployment --region ${AWS_REGION}
                aws ecs update-service --cluster ${ECS_CLUSTER} --service food-admin-service --force-new-deployment --region ${AWS_REGION}
                """
            }
        }
    }
}
