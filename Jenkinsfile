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
                sh '''
                aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin ://amazonaws.com
                '''
            }
        }

        stage('Build & Push to ECR') {
            steps {
                sh '''
                docker build -t ://amazonaws.com/food-backend:latest ./backend
                docker build -t ://amazonaws.com/food-frontend:latest ./frontend
                docker build -t ://amazonaws.com/food-admin:latest ./admin

                docker push ://amazonaws.com/food-backend:latest
                docker push ://amazonaws.com/food-frontend:latest
                docker push ://amazonaws.com/food-admin:latest
                '''
            }
        }

        stage('Deploy to Amazon ECS') {
            steps {
                sh '''
                aws ecs update-service --cluster food-cluster --service food-backend-service --force-new-deployment --region ap-south-1
                aws ecs update-service --cluster food-cluster --service food-admin-service --force-new-deployment --region ap-south-1
                '''
            }
        }
    }
}
