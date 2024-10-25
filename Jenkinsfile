pipeline {
    agent any

    environment {
        DOTNET_PROJECT_PATH = 'src/Server/Server.csproj' // Path to the .NET server project
        PUBLISH_OUTPUT = 'publish' // Publish output directory
        DOTNET_ENVIRONMENT = 'Production' // Replace with your desired environment name
        DOTNET_ConnectionStrings__SqlDatabase = 'your-sql-server-connection-string' // Replace with actual connection string
    }

    stages {
        stage('Restore Dependencies') {
            steps {
                script {
                    // Restore dependencies
                    sh "dotnet restore ${DOTNET_PROJECT_PATH}"
                }
            }
        }

        stage('Build Application') {
            steps {
                script {
                    // Build the project
                    sh "dotnet build ${DOTNET_PROJECT_PATH} -c Release"
                }
            }
        }

        stage('Publish Application') {
            steps {
                script {
                    // Publish the project to the specified directory
                    sh "dotnet publish ${DOTNET_PROJECT_PATH} -c Release -o ${PUBLISH_OUTPUT}"
                }
            }
        }

        stage('Deployment to Remote Server') {
            when {
                expression { return params.DEPLOY_TO_TEST } // Manual trigger for CI mode
            }
            steps {
                script {
                    // Copy the published files to the remote server and run the application
                    sh '''
                        scp -i ~/.ssh/id_rsa ${PUBLISH_OUTPUT}/* user@remote-server:/path/to/remote/deploy
                        ssh -i ~/.ssh/id_rsa user@remote-server "
                            export DOTNET_ENVIRONMENT=${DOTNET_ENVIRONMENT} \
                                   DOTNET_ConnectionStrings__SqlDatabase='${DOTNET_ConnectionStrings__SqlDatabase}' && \
                            dotnet /path/to/remote/deploy/Server.dll
                        "
                    '''
                }
            }
        }
    }

    post {
        always {
            echo 'Build process completed.'
        }
        success {
            echo 'Build and deployment successful!'
        }
        failure {
            echo 'Build or deployment failed.'
        }
    }
}
