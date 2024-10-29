pipeline {
    agent { label 'App' }

    environment {
        DOTNET_PROJECT_PATH = 'p3ops-demo-app/src/Server/Server.csproj'
        PUBLISH_OUTPUT = 'publish'
        DOTNET_ENVIRONMENT = 'Production'
        DOTNET_ConnectionStrings__SqlDatabase = '"SqlDatabase": "Server=localhost,1433;Database={{ database_name }};User Id=sa;Password={{ sa_password }};Trusted_Connection=False;MultipleActiveResultSets=True;"' // Replace with actual connection string
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
            steps {
                script {
                    // Copy the published files to the remote server and run the application
                    sh '''
                        scp -i ~/.ssh/id_rsa ${PUBLISH_OUTPUT}/* vagrant@172.16.128.101:/vagrant/output-pipeline
                        ssh -i ~/.ssh/id_rsa vagrant@r172.16.128.101 "
                            export DOTNET_ENVIRONMENT=${DOTNET_ENVIRONMENT} \
                                   DOTNET_ConnectionStrings__SqlDatabase='${DOTNET_ConnectionStrings__SqlDatabase}' && \
                            dotnet /vagrant/output-pipeline/Server.dll
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
