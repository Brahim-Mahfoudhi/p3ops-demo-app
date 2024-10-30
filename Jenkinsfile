pipeline {
    agent { label 'App' }

    environment {
        DOTNET_PROJECT_PATH = 'p3ops-demo-app/src/Server/Server.csproj'
        PUBLISH_OUTPUT = 'publish'
        DOTNET_ENVIRONMENT = 'Production'
        DOTNET_CONNECTION_STRING = "Server=localhost,1433;Database=SportStore;User Id=sa;Password=Drgnnrblnc19;Trusted_Connection=False;MultipleActiveResultSets=True;"
        DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/1301160382307766292/kROxjtgZ-XVOibckTMri2fy5-nNOEjzjPLbT9jEpr_R0UH9JG0ZXb2XzUsYGE0d3yk6I"
    }

    stages {
        stage('Checkout Code') {
            steps {
                script {
                    echo "Checking out code..."
                    git url: 'https://github.com/Brahim-Mahfoudhi/p3ops-demo-app.git', branch: 'master'
                }
            }
        }

        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Restore Dependencies') {
            steps {
                echo "Restoring dependencies..."
                sh "dotnet restore ${DOTNET_PROJECT_PATH}"
            }
        }

        stage('Build Application') {
            steps {
                echo "Building application..."
                sh "dotnet build ${DOTNET_PROJECT_PATH} -c Release"
            }
        }

        stage('Publish Application') {
            steps {
                echo "Publishing application..."
                sh "dotnet publish ${DOTNET_PROJECT_PATH} -c Release -o ${PUBLISH_OUTPUT}"
            }
        }

        stage('Capture Git Info') {
            steps {
                script {
                    try {
                        echo "Capturing Git information..."
                        env.GIT_AUTHOR_NAME = sh(script: "git show -s --pretty=format:'%an'", returnStdout: true).trim() ?: "Unknown Author"
                        env.GIT_AUTHOR_EMAIL = sh(script: "git show -s --pretty=format:'%ae'", returnStdout: true).trim() ?: "Unknown Email"
                        env.GIT_COMMIT_MESSAGE = sh(script: "git show -s --pretty=format:'%s'", returnStdout: true).trim() ?: "No commit message"
                        env.GIT_COMMIT = sh(script: "git rev-parse HEAD", returnStdout: true).trim() ?: "Unknown Commit"
                        env.GIT_BRANCH = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim() ?: "Unknown Branch"

                        // Debug output
                        echo "Author: ${env.GIT_AUTHOR_NAME}, Email: ${env.GIT_AUTHOR_EMAIL}, Commit: ${env.GIT_COMMIT}, Message: ${env.GIT_COMMIT_MESSAGE}, Branch: ${env.GIT_BRANCH}"
                    } catch (Exception e) {
                        echo "Error capturing Git information: ${e.message}"
                    }
                }
            }
        }

        stage('Deploy to Remote Server') {
            steps {
                script {
                    echo "Deploying to remote server..."
                    def remoteHost = "vagrant@172.16.128.101"
                    def sshKey = "~/.ssh/id_rsa"

                    sh """
                        scp -i ${sshKey} -r ${PUBLISH_OUTPUT}/* ${remoteHost}:/vagrant/output-pipeline || exit 1
                        ssh -i ${sshKey} ${remoteHost} '
                            export DOTNET_ENVIRONMENT=${DOTNET_ENVIRONMENT} &&
                            export DOTNET_CONNECTION_STRING="${DOTNET_CONNECTION_STRING}" &&
                            nohup dotnet /vagrant/output-pipeline/Server.dll > app.log 2>&1 &
                        ' || exit 1
                    """
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
        def description = """
            Build #${env.BUILD_NUMBER} ${status == "Build Success" ? 'completed successfully!' : 'has failed!'}

            **Commit**: ${env.GIT_COMMIT}
            **Author**: ${env.GIT_AUTHOR_NAME} <${env.GIT_AUTHOR_EMAIL}>
            **Branch**: ${env.GIT_BRANCH}
            **Message**: ${env.GIT_COMMIT_MESSAGE}

            [**Report**](http://172.16.128.100:8080/job/${env.JOB_NAME}/${env.BUILD_NUMBER}/) - Detailed build report
        """
        
        discordSend(
            title: "${env.JOB_NAME} - ${status}",
            description: description,
            footer: "Build Duration: ${currentBuild.durationString.replace(' and counting', '')}",
            webhookURL: DISCORD_WEBHOOK_URL,
            result: status == "Build Success" ? 'SUCCESS' : 'FAILURE'
        )
    }
}
