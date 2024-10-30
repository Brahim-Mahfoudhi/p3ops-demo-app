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
                description: "Build #${env.BUILD_NUMBER} completed successfully!",
                footer: "Build Duration: ${currentBuild.durationString.replace(' and counting', '')}",
                link: env.BUILD_URL,
                result: 'SUCCESS',
                title: "${env.JOB_NAME} - Build Success",
                webhookURL: "https://discord.com/api/webhooks/1301160382307766292/kROxjtgZ-XVOibckTMri2fy5-nNOEjzjPLbT9jEpr_R0UH9JG0ZXb2XzUsYGE0d3yk6I",
                fields: [
                    [name: "Commit", value: "${env.GIT_COMMIT}", inline: true],
                    [name: "Author", value: "${env.GIT_AUTHOR_NAME} <${env.GIT_AUTHOR_EMAIL}>", inline: true],
                    [name: "Branch", value: "${env.GIT_BRANCH}", inline: true]
                ]
            )
            archiveArtifacts artifacts: '**/*.dll', fingerprint: true
        }
        
        failure {
            echo 'Build or deployment has failed.'
            discordSend(
                description: "Build #${env.BUILD_NUMBER} has failed!",
                footer: "Build Duration: ${currentBuild.durationString.replace(' and counting', '')}",
                link: env.BUILD_URL,
                result: 'FAILURE',
                title: "${env.JOB_NAME} - Build Failed",
                webhookURL: "https://discord.com/api/webhooks/1301160382307766292/kROxjtgZ-XVOibckTMri2fy5-nNOEjzjPLbT9jEpr_R0UH9JG0ZXb2XzUsYGE0d3yk6I",
                fields: [
                    [name: "Commit", value: "${env.GIT_COMMIT}", inline: true],
                    [name: "Author", value: "${env.GIT_AUTHOR_NAME} <${env.GIT_AUTHOR_EMAIL}>", inline: true],
                    [name: "Branch", value: "${env.GIT_BRANCH}", inline: true]
                ]
            )
        }
    }
}
