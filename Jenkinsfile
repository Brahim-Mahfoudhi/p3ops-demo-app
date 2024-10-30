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
                    git url: 'https://your-repo-url.git', branch: 'master' // Replace with your repository URL
                }
            }
        }

        stage('Capture Git Info') {
            steps {
                script {
                    try {
                        echo "Capturing Git information..."
                        def latestCommit = sh(script: "git rev-parse HEAD", returnStdout: true).trim()
                        env.GIT_COMMIT = latestCommit

                        // Capture author and message
                        def commitDetails = sh(script: "git show -s ${latestCommit} --pretty=format:'%an;%ae;%s'", returnStdout: true).trim()
                        def detailsArray = commitDetails.split(";")

                        env.GIT_AUTHOR_NAME = detailsArray.size() > 0 ? detailsArray[0] : "Unknown Author"
                        env.GIT_AUTHOR_EMAIL = detailsArray.size() > 1 ? detailsArray[1] : "Unknown Email"
                        env.GIT_COMMIT_MESSAGE = detailsArray.size() > 2 ? detailsArray[2] : "No commit message"
                        env.GIT_BRANCH = sh(script: "git rev-parse --abbrev-ref HEAD", returnStdout: true).trim() ?: "Unknown Branch"

                        // Debug output
                        echo "Author: ${env.GIT_AUTHOR_NAME}, Email: ${env.GIT_AUTHOR_EMAIL}, Commit: ${env.GIT_COMMIT}, Message: ${env.GIT_COMMIT_MESSAGE}, Branch: ${env.GIT_BRANCH}"
                    } catch (Exception e) {
                        echo "Error capturing Git information: ${e.message}"
                    }
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
