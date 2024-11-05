pipeline {
    agent { label 'App' }

    environment {
        DOTNET_PROJECT_PATH = 'p3ops-demo-app/src/Server/Server.csproj'
        PUBLISH_OUTPUT = 'publish'
        DOTNET_ENVIRONMENT = 'Production'
        DOTNET_CONNECTION_STRING = 'Server=localhost,1433;Database=SportStore;User Id=sa;Password=Drgnnrblnc19;Trusted_Connection=False;MultipleActiveResultSets=True;'
        DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/1301160382307766292/kROxjtgZ-XVOibckTMri2fy5-nNOEjzjPLbT9jEpr_R0UH9JG0ZXb2XzUsYGE0d3yk6I"
        JENKINS_CREDENTIALS_ID = "jenkins-master-key"
        SSH_KEY_FILE = '/var/lib/jenkins/.ssh/id_rsa' 
    }

    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Checkout Code') {
            steps {
                git url: 'https://github.com/Brahim-Mahfoudhi/p3ops-demo-app.git'
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
                sshagent([JENKINS_CREDENTIALS_ID]) {
                    script {
                        def remoteHost = "jenkins@172.16.128.101"
                        sh """
                            # Copy files to the remote server
                            scp -i ${SSH_KEY_FILE} -r ${PUBLISH_OUTPUT}/* ${remoteHost}:/vagrant/output-pipeline
                            
                            # Run the application on the remote server
                            ssh -i ${SSH_KEY_FILE} ${remoteHost} '
                                export DOTNET_ENVIRONMENT=${DOTNET_ENVIRONMENT} &&
                                export DOTNET_CONNECTION_STRING="${DOTNET_CONNECTION_STRING}" &&
                                nohup dotnet /var/lib/jenkins/app/Server.dll > app.log 2>&1 &
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

def mysh(cmd) {
    sh('#!/bin/sh -e\n' + cmd)
}

def sendDiscordNotification(status) {
    script {
        // Using mysh to gather Git information
        gitInfo = mysh('''
            # Gather Git information without printing commands
            AUTHOR_NAME=$(git show -s HEAD --pretty=format:"%an" 2>/dev/null)
            AUTHOR_EMAIL=$(git show -s HEAD --pretty=format:"%ae" 2>/dev/null)
            COMMIT_MESSAGE=$(git show -s HEAD --pretty=format:"%s" 2>/dev/null)
            GIT_COMMIT=$(git rev-parse HEAD 2>/dev/null)
            GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
          ''')

        // Set environment variables without exposing them in the console
        env.GIT_AUTHOR_NAME = gitInfo[0]
        env.GIT_AUTHOR_EMAIL = gitInfo[1]
        env.GIT_COMMIT_MESSAGE = gitInfo[2]
        env.GIT_COMMIT = gitInfo[3]
        env.GIT_BRANCH = gitInfo[4]

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

