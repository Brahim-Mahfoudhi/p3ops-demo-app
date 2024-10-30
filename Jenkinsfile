pipeline {
    agent { label 'App' }

    environment {
        DOTNET_PROJECT_PATH = 'p3ops-demo-app/src/Server/Server.csproj'
        PUBLISH_OUTPUT = 'publish'
        DOTNET_ENVIRONMENT = 'Production'
        DOTNET_CONNECTION_STRING = "Server=localhost,1433;Database=SportStore;User Id=sa;Password=Drgnnrblnc19;Trusted_Connection=False;MultipleActiveResultSets=True;"
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Restore Dependencies') {
            steps {
                sh "dotnet restore ${DOTNET_PROJECT_PATH}"
            }
        }

        stage('Build Application') {
            steps {
                sh "dotnet build ${DOTNET_PROJECT_PATH} -c Release"
            }
        }

        stage('Publish Application') {
            steps {
                sh "dotnet publish ${DOTNET_PROJECT_PATH} -c Release -o ${PUBLISH_OUTPUT}"
            }
        }

        stage('Deploy to Remote Server') {
            steps {
                script {
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
            discordSend(
                description: """
                ${env.JOB_NAME} - Build Success
    
                Build #${env.BUILD_NUMBER} completed successfully!
    
                **Commit**: ${env.GIT_COMMIT}
                **Author**: ${env.GIT_AUTHOR_NAME} <${env.GIT_AUTHOR_EMAIL}>
                **Branch**: ${env.GIT_BRANCH}
                **Message**: ${env.GIT_COMMIT_MESSAGE}
    
                [**Report**](${JENKINS_URL}job/${env.JOB_NAME}/${env.BUILD_NUMBER}/) - Detailed build report
                """,
                footer: "Build Duration: ${currentBuild.durationString.replace(' and counting', '')}",
                link: "${JENKINS_URL}job/${env.JOB_NAME}/${env.BUILD_NUMBER}/",
                result: 'SUCCESS',
                title: "${env.JOB_NAME} - Build Success",
                webhookURL: "https://discord.com/api/webhooks/your_webhook_url"
            )
            archiveArtifacts artifacts: '**/*.dll', fingerprint: true
        }
    
        failure {
            echo 'Build or deployment has failed.'
            discordSend(
                description: """
                ${env.JOB_NAME} - Build Failed
    
                Build #${env.BUILD_NUMBER} has failed!
    
                **Commit**: ${env.GIT_COMMIT}
                **Author**: ${env.GIT_AUTHOR_NAME} <${env.GIT_AUTHOR_EMAIL}>
                **Branch**: ${env.GIT_BRANCH}
                **Message**: ${env.GIT_COMMIT_MESSAGE}
    
                [**Report**](${JENKINS_URL}job/${env.JOB_NAME}/${env.BUILD_NUMBER}/) - Detailed build report
                """,
                footer: "Build Duration: ${currentBuild.durationString.replace(' and counting', '')}",
                link: "${JENKINS_URL}job/${env.JOB_NAME}/${env.BUILD_NUMBER}/",
                result: 'FAILURE',
                title: "${env.JOB_NAME} - Build Failed",
                webhookURL: "https://discord.com/api/webhooks/your_webhook_url"
            )
        }
        
        always {
            echo 'Build process has completed.'
        }
    }
}
