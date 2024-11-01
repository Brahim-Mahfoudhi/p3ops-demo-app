pipeline {
    agent { label 'App' }

    environment {
        DOTNET_PROJECT_PATH = 'p3ops-demo-app/src/Server/Server.csproj'
        PUBLISH_OUTPUT = 'publish'
        DOTNET_ENVIRONMENT = 'Production'
        DOTNET_CONNECTION_STRING = credentials('your-credential-id') // Use Jenkins credentials
        DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/1301160382307766292/kROxjtgZ-XVOibckTMri2fy5-nNOEjzjPLbT9jEpr_R0UH9JG0ZXb2XzUsYGE0d3yk6I"
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout Code') {
            steps {
                echo "Checking out code..."
                git url: 'https://github.com/Brahim-Mahfoudhi/p3ops-demo-app.git', branch: 'master'
            }
        }

        stage('Capture Git Info') {
            steps {
                script {
                    def commitDetails = sh(script: "git show -s HEAD --pretty=format:'%an;%ae;%s'", returnStdout: true).trim().split(";")
                    env.GIT_COMMIT = sh(script: "git rev-parse HEAD", returnStdout: true).trim()
                    env.GIT_AUTHOR_NAME = commitDetails[0] ?: "Unknown Author"
                    env.GIT_AUTHOR_EMAIL = commitDetails[1] ?: "Unknown Email"
                    env.GIT_COMMIT_MESSAGE = commitDetails[2] ?: "No commit message"
                    env.GIT_BRANCH = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim() ?: "Unknown Branch"
                    echo "Author: ${env.GIT_AUTHOR_NAME}, Email: ${env.GIT_AUTHOR_EMAIL}, Commit: ${env.GIT_COMMIT}, Message: ${env.GIT_COMMIT_MESSAGE}, Branch: ${env.GIT_BRANCH}"
                }
            }
        }

        stage('Restore, Build, and Publish') {
            steps {
                sh """
                    echo "Restoring dependencies..."
                    dotnet restore ${DOTNET_PROJECT_PATH}
                    echo "Building application..."
                    dotnet build ${DOTNET_PROJECT_PATH} -c Release
                    echo "Publishing application..."
                    dotnet publish ${DOTNET_PROJECT_PATH} -c Release -o ${PUBLISH_OUTPUT}
                """
            }
        }

        stage('Deploy to Remote Server') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'jenkins-master-key', 
                                                   keyFileVariable: 'SSH_KEY_FILE',
                                                   usernameVariable: 'SSH_USER')]) {
                    script {
                        def remoteHost = "${SSH_USER}@172.16.128.101"
                        
                        sh """
                            # Copy files to the remote server
                            scp -i ${SSH_KEY_FILE} -r ${PUBLISH_OUTPUT}/* ${remoteHost}:/vagrant/output-pipeline
                            
                            # Run the application on the remote server
                            ssh -i ${SSH_KEY_FILE} ${remoteHost} '
                                export DOTNET_ENVIRONMENT=${DOTNET_ENVIRONMENT} &&
                                export DOTNET_CONNECTION_STRING="${DOTNET_CONNECTION_STRING}" &&
                                nohup dotnet /vagrant/output-pipeline/Server.dll > app.log 2>&1 &
                            '
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Build and deployment completed successfully!'
            script {
                sendDiscordNotification("Build Success")
            }
            archiveArtifacts artifacts: '**/*.dll', fingerprint: true
        }
        failure {
            echo 'Build or deployment has failed.'
            script {
                sendDiscordNotification("Build Failed")
            }
        }
        always {
            echo 'Build process has completed.'
        }
    }
}

def sendDiscordNotification(status) {
    script {
        discordSend(
            title: "${env.JOB_NAME} - ${status}",
            description: """
                Build #${env.BUILD_NUMBER} ${status == "Build Success" ? 'completed successfully!' : 'has failed!'}
                **Commit**: ${en
