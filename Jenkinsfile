pipeline {
    agent { label 'food-agent' }

    environment {
        //  app server Private IP
        APP_SERVER_IP = "172.31.6.81" 
    }

    stages {
        stage('Build & Push to ECR') {
            steps {
               
                echo "Building Docker Images..."
                // sh 'docker build -t ...'
                echo "Pushing to AWS ECR..."
                // sh 'docker push ...'
            }
        }

        stage('Deploy to App Server') {
            steps {
                
                sshagent(['app-server-key']) {
                    sh """
                    ssh -o StrictHostKeyChecking=no ubuntu@${APP_SERVER_IP} 'cd IPT_08 && docker compose pull && docker compose up -d'
                    """
                }
            }
        }
    }
}
