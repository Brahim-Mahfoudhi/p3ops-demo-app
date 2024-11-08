pipeline {
    agent { label 'App' }
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    environment {
        DOTNET_PROJECT_PATH = 'p3ops-demo-app/src/Server/Server.csproj'
        DOTNET_TEST_PATH = 'p3ops-demo-app/tests/Domain.Tests/Domain.Tests.csproj'
        PUBLISH_OUTPUT = 'publish'
        DOTNET_ENVIRONMENT = 'Production'
        DOTNET_CONNECTION_STRING = 'Server=localhost,1433;Database=SportStore;User Id=sa;Password=Drgnnrblnc19;Trusted_Connection=False;MultipleActiveResultSets=True;'
        DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/1301160382307766292/kROxjtgZ-XVOibckTMri2fy5-nNOEjzjPLbT9jEpr_R0UH9JG0ZXb2XzUsYGE0d3yk6I"
        JENKINS_CREDENTIALS_ID = "jenkins-master-key"
        SSH_KEY_FILE = '/var/lib/jenkins/.ssh/id_rsa' 
        REMOTE_HOST = 'jenkins@172.16.128.101'
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }
        
        stage('Checkout Code') {
            steps {
                script {
                    // Checkout code
                    git url: 'https://github.com/Brahim-Mahfoudhi/p3ops-demo-app.git'
                    
                    // Gather GitHub info
                    echo 'Gather GitHub info!'
                    def gitInfo = sh(script: 'git show -s HEAD --pretty=format:"%an%n%ae%n%s%n%H%n%h" 2>/dev/null', returnStdout: true).trim().split("\n")
                    env.GIT_AUTHOR_NAME = gitInfo[0]
                    env.GIT_AUTHOR_EMAIL = gitInfo[1]
                    env.GIT_COMMIT_MESSAGE = gitInfo[2]
                    env.GIT_COMMIT = gitInfo[3]
                    env.GIT_BRANCH = gitInfo[4]
                }
            }
        }

        stage('Restore Dependencies') {
            steps {
                sh "dotnet restore ${DOTNET_PROJECT_PATH}"
                sh "dotnet restore ${DOTNET_TEST_PATH}"
            }
        }

        stage('Build Application') {
            steps {
                sh "dotnet build ${DOTNET_PROJECT_PATH}"
            }
        }

       /* stage('Install xUnit Logger') {
            steps {
                // Install the xUnit logger package
                sh """
                    dotnet add p3ops-demo-app/tests/Domain.Tests/Domain.Tests.csproj package xunit
                    dotnet add p3ops-demo-app/tests/Domain.Tests/Domain.Tests.csproj package xunit.runner.visualstudio --version 2.5.3

                """
            }
        } */

        stage('Running Unit Tests') {
            steps {
                sh """
                   mkdir -p coverage
                   dotnet test ${DOTNET_TEST_PATH} --logger "trx;LogFileName=test-report.trx" 
                """
                /*/p:CollectCoverage=true /p:CoverletOutputFormat=cobertura /p:CoverletOutput=${env.WORKSPACE}/coverage/coverage.cobertura.xml*/
            }
        }

        stage('Publish Application') {
            steps {
                sh "dotnet publish ${DOTNET_PROJECT_PATH} -c Release -o ${PUBLISH_OUTPUT}"
            }
        }

        stage('Deploy to Remote Server') {
            steps {
                sshagent([JENKINS_CREDENTIALS_ID]) {
                    script {
                        sh """
                            # Copy files to the remote server
                            scp -i ${SSH_KEY_FILE} -o StrictHostKeyChecking=no -r ${PUBLISH_OUTPUT}/* ${REMOTE_HOST}:/var/lib/jenkins/artifacts/
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
            archiveArtifacts artifacts: 'p3ops-demo-app/tests/Domain.Tests/TestResults/test-report.trx', fingerprint: true
            //archiveArtifacts artifacts: 'coverage/coverage.cobertura.xml', fingerprint: true
            // junit 'p3ops-demo-app/tests/Domain.Tests/TestResults/test-report.trx'
        }
        failure {
            echo 'Build or deployment has failed.'
            script {
                sendDiscordNotification("Build Failed")
            }
        }
        always {
            echo 'Build process has completed.'
            echo 'Generate Test report...'
            //sh 'mkdir -p reports'
            publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: true, reportDir: 'p3ops-demo-app/tests/Domain.Tests/TestResults', reportFiles: 'test-report. trx', reportName: 'Build Report'])
        }
    }
}

def sendDiscordNotification(status) {
    script {
        discordSend(
            title: "${env.JOB_NAME} - ${status}",
            description: """
                Build #${env.BUILD_NUMBER} ${status == "Build Success" ? 'completed successfully!' : 'has failed!'}
                **Commit**: ${env.GIT_COMMIT}
                **Author**: ${env.GIT_AUTHOR_NAME} <${env.GIT_AUTHOR_EMAIL}>
                **Branch**: ${env.GIT_BRANCH}
                **Message**: ${env.GIT_COMMIT_MESSAGE}
                
                [**Report**](http://172.16.128.100:8080/job/${env.JOB_NAME}/${env.BUILD_NUMBER}/console) - Detailed build report
            """,
            footer: "Build Duration: ${currentBuild.durationString.replace(' and counting', '')}",
            webhookURL: DISCORD_WEBHOOK_URL,
            result: status == "Build Success" ? 'SUCCESS' : 'FAILURE'
        )
    }
}
