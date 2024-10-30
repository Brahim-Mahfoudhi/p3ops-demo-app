pipeline {
    agent { label 'App' }

    environment {
        DOTNET_PROJECT_PATH = 'p3ops-demo-app/src/Server/Server.csproj'
        PUBLISH_OUTPUT = 'publish'
        DOTNET_ENVIRONMENT = 'Production'
        DOTNET_ConnectionStrings__SqlDatabase = "Server=localhost,1433;Database=SportStore;User Id=sa;Password=Drgnnrblnc19;Trusted_Connection=False;MultipleActiveResultSets=True;"
    }

    stages {
        stage('Clean workspace') {
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

        stage('Deployment to Remote Server') {
            steps {
                sh '''
                    scp -i ~/.ssh/id_rsa -r ${PUBLISH_OUTPUT}/* vagrant@172.16.128.101:/vagrant/output-pipeline || exit 1
                    ssh -i ~/.ssh/id_rsa vagrant@172.16.128.101 "
                        export DOTNET_ENVIRONMENT=${DOTNET_ENVIRONMENT} \
                               DOTNET_ConnectionStrings__SqlDatabase='${DOTNET_ConnectionStrings__SqlDatabase}' && \
                        nohup dotnet /vagrant/output-pipeline/Server.dll > app.log 2>&1 &
                    " || exit 1
                '''
            }
        }
    }

    post {
        success {
            echo 'Build and deployment completed successfully!'
            discordSend(
                description: """
                Build #${env.BUILD_NUMBER} completed successfully!
        
                **Commit**: ${env.GIT_COMMIT}
                **Author**: ${env.GIT_AUTHOR_NAME} <${env.GIT_AUTHOR_EMAIL}>
                **Branch**: ${env.GIT_BRANCH}
                **Message**: ${env.GIT_COMMIT_MESSAGE}
                
                [**Report**](${env.BUILD_URL}) - Detailed build report
                """,
                footer: "Build Duration: ${currentBuild.durationString.replace(' and counting', '')}",
                link: env.BUILD_URL,
                result: 'SUCCESS',
                title: "${env.JOB_NAME} - Build Success",
                webhookURL: "https://discord.com/api/webhooks/your-webhook-url"
            )
            archiveArtifacts artifacts: '**/*.dll', fingerprint: true
        }
        
        failure {
            echo 'Build or deployment has failed.'
            discordSend(
                description: """
                Build #${env.BUILD_NUMBER} has failed!
        
                **Commit**: ${env.GIT_COMMIT}
                **Author**: ${env.GIT_AUTHOR_NAME} <${env.GIT_AUTHOR_EMAIL}>
                **Branch**: ${env.GIT_BRANCH}
                **Message**: ${env.GIT_COMMIT_MESSAGE}
                
                [**Report**](${env.BUILD_URL}) - Detailed build report
                """,
                footer: "Build Duration: ${currentBuild.durationString.replace(' and counting', '')}",
                link: env.BUILD_URL,
                result: 'FAILURE',
                title: "${env.JOB_NAME} - Build Failed",
                webhookURL: "https://discord.com/api/webhooks/your-webhook-url"
            )
        }

    }
}
