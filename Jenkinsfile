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

        stage('Capture Git Info') {
            steps {
                script {
                    // Capture the author name and other info
                    def authorName = sh(script: "git show -s --pretty=%an", returnStdout: true).trim()
                    def authorEmail = sh(script: "git show -s --pretty=%ae", returnStdout: true).trim()
                    def commitMessage = sh(script: "git show -s --pretty=%B", returnStdout: true).trim()
                    def commitHash = sh(script: "git rev-parse HEAD", returnStdout: true).trim()

                    // Set environment variables for later use
                    env.GIT_AUTHOR_NAME = authorName
                    env.GIT_AUTHOR_EMAIL = authorEmail
                    env.GIT_COMMIT_MESSAGE = commitMessage
                    env.GIT_COMMIT = commitHash
                }
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
            script {
                try {
                    discordSend(
                        title: "${env.JOB_NAME} - Build Success",
                        description: """
                            Build #${env.BUILD_NUMBER} completed successfully!

                            **Commit**: ${env.GIT_COMMIT}
                            **Author**: ${env.GIT_AUTHOR_NAME} <${env.GIT_AUTHOR_EMAIL}>
                            **Branch**: ${env.GIT_BRANCH}
                            **Message**: ${env.GIT_COMMIT_MESSAGE}

                            [**Report**](http://172.16.128.100:8080/job/${env.JOB_NAME}/${env.BUILD_NUMBER}/) - Detailed build report
                        """,
                        footer: "Build Duration: ${currentBuild.durationString.replace(' and counting', '')}",
                        webhookURL: "https://discord.com/api/webhooks/1301160382307766292/kROxjtgZ-XVOibckTMri2fy5-nNOEjzjPLbT9jEpr_R0UH9JG0ZXb2XzUsYGE0d3yk6I",
                        result: 'SUCCESS'
                    )
                } catch (Exception e) {
                    echo "Failed to send Discord notification: ${e.message}"
                }
            }
            archiveArtifacts artifacts: '**/*.dll', fingerprint: true
        }

        failure {
            echo 'Build or deployment has failed.'
            script {
                try {
                    discordSend(
                        title: "${env.JOB_NAME} - Build Failed",
                        description: """
                            Build #${env.BUILD_NUMBER} has failed!

                            **Commit**: ${env.GIT_COMMIT}
                            **Author**: ${env.GIT_AUTHOR_NAME} <${env.GIT_AUTHOR_EMAIL}>
                            **Branch**: ${env.GIT_BRANCH}
                            **Message**: ${env.GIT_COMMIT_MESSAGE}

                            [**Report**](http://172.16.128.100:8080/job/${env.JOB_NAME}/${env.BUILD_NUMBER}/) - Detailed build report
                        """,
                        footer: "Build Duration: ${currentBuild.durationString.replace(' and counting', '')}",
                        webhookURL: "https://discord.com/api/webhooks/1301160382307766292/kROxjtgZ-XVOibckTMri2fy5-nNOEjzjPLbT9jEpr_R0UH9JG0ZXb2XzUsYGE0d3yk6I",
                        result: 'FAILURE'
                    )
                } catch (Exception e) {
                    echo "Failed to send Discord notification: ${e.message}"
                }
            }
        }
        
        always {
            echo 'Build process has completed.'
        }
    }
}
