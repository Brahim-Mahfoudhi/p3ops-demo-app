pipeline {
    agent { label 'App' }

    environment {
        DOTNET_PROJECT_PATH = 'p3ops-demo-app/src/Server/Server.csproj'
        PUBLISH_OUTPUT = 'publish'
        DOTNET_ENVIRONMENT = 'Production'
        DOTNET_ConnectionStrings__SqlDatabase = "Server=localhost,1433;Database=SportStore;User Id=sa;Password=Drgnnrblnc19;Trusted_Connection=False;MultipleActiveResultSets=True;"
        DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1301160382307766292/kROxjtgZ-XVOibckTMri2fy5-nNOEjzjPLbT9jEpr_R0UH9JG0ZXb2XzUsYGE0d3yk6Ié"
    }

    stages {
        stage('Clean workspace') {
            steps {
                cleanWs()
            }
        }

        stage('Restore Dependencies') {
            steps {
                script {
                    sh "dotnet restore ${DOTNET_PROJECT_PATH}"
                }
            }
        }

        stage('Linting and Static Code Analysis') {
            steps {
                script {
                   // sh "dotnet format ${DOTNET_PROJECT_PATH} --check"
                }
            }
        }

        stage('Build Application') {
            steps {
                script {
                    sh "dotnet build ${DOTNET_PROJECT_PATH} -c Release"
                }
            }
        }

        stage('Run Unit Tests') {
            steps {
                script {
                   // sh "dotnet test ${DOTNET_PROJECT_PATH} --logger trx;logfilename=TestResults.trx"
                }
            }
        }

        stage('Publish Application') {
            steps {
                script {
                    sh "dotnet publish ${DOTNET_PROJECT_PATH} -c Release -o ${PUBLISH_OUTPUT}"
                }
            }
        }

        stage('Deployment to Remote Server') {
            steps {
                script {
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
    }

    post {
        always {
            script {
                archiveArtifacts artifacts: '**/*.dll', fingerprint: true
                // junit '**/TestResults/*.xml'
                echo 'Build process completed.'
                
                // Send Discord notification
                discordSend(
                    description: "Jenkins Pipeline Build",
                    footer: "Footer Text",
                    link: env.BUILD_URL,
                    result: currentBuild.currentResult,
                    title: env.JOB_NAME,
                    webhookURL: "${DISCORD_WEBHOOK}"
                )
            }
        }
        success {
            echo 'Build and deployment successful!'
            
            // Send success notification to Discord
            discordSend(
                description: "Jenkins Pipeline Build",
                footer: "Footer Text",
                link: env.BUILD_URL,
                result: 'SUCCESS',
                title: "${env.JOB_NAME} - Build Successful",
                webhookURL: "${DISCORD_WEBHOOK}"
            )
        }
        failure {
            echo 'Build or deployment failed.'
            
            // Send failure notification to Discord
            discordSend(
                description: "Jenkins Pipeline Build",
                footer: "Footer Text",
                link: env.BUILD_URL,
                result: 'FAILURE',
                title: "${env.JOB_NAME} - Build Failed",
                webhookURL: "${DISCORD_WEBHOOK}"
            )
        }
    }
}
