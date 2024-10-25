pipeline {
    agent any

    environment {
        DOTNET_PROJECT_PATH = 'path/to/dotnet/project'    // Pad naar je .NET-project
        ANDROID_PROJECT_PATH = 'path/to/android/project'  // Pad naar je Android-project
        TEST_ENV_URL = 'http://test-server-url'           // URL van de testserver
    }

    stages {
        stage('Linting & Static Analysis') {
            parallel {
                stage('Lint .NET Code') {
                    steps {
                        script {
                            // .NET linting commando
                            sh 'dotnet tool install --global dotnet-format'
                            sh 'dotnet format ${DOTNET_PROJECT_PATH} --check'
                        }
                    }
                }
                stage('Lint Android Code') {
                    steps {
                        // Lint Android code
                        sh './gradlew lint'
                    }
                }
            }
        }

        stage('Build & Compile') {
            parallel {
                stage('Build .NET Application') {
                    steps {
                        script {
                            // .NET build commando
                            sh 'dotnet build ${DOTNET_PROJECT_PATH} --configuration Release'
                        }
                    }
                }
                stage('Build Android Application') {
                    steps {
                        // Android build commando
                        sh './gradlew assembleRelease'
                    }
                }
            }
        }

        stage('Unit Tests') {
            parallel {
                stage('Test .NET Application') {
                    steps {
                        script {
                            // .NET unit tests
                            sh 'dotnet test ${DOTNET_PROJECT_PATH}'
                        }
                    }
                }
                stage('Test Android Application') {
                    steps {
                        // Android unit tests
                        sh './gradlew test'
                    }
                }
            }
        }

        stage('Code Coverage') {
            steps {
                script {
                    // Code coverage voor .NET
                    sh 'dotnet test ${DOTNET_PROJECT_PATH} --collect:"XPlat Code Coverage"'
                }
                // Voeg een stap toe voor het uploaden van code coverage rapport
                publishHTML(target: [
                    reportName: 'Code Coverage Report',
                    reportDir: 'path/to/code-coverage/report',
                    reportFiles: 'index.html'
                ])
            }
        }

        stage('Packaging Android App') {
            steps {
                // Verpak de Android-applicatie klaar voor publicatie
                sh 'zip -r ${ANDROID_PROJECT_PATH}/build/outputs/apk/release/app-release.apk output/release/app-release.zip'
                archiveArtifacts artifacts: 'output/release/app-release.zip', allowEmptyArchive: true
            }
        }

        stage('Deployment to Test Environment') {
            when {
                expression { return params.DEPLOY_TO_TEST } // Voeg een parameter toe om manueel uit te voeren voor CI
            }
            steps {
                script {
                    // Deploy de .NET applicatie naar testomgeving
                    sh 'scp -i ~/.ssh/id_rsa ${DOTNET_PROJECT_PATH}/bin/Release/netcoreapp3.1/publish/* user@${TEST_ENV_URL}:/path/to/test/environment'
                }
            }
        }

        stage('Automated Acceptance Tests') {
            when {
                expression { return params.RUN_ACCEPTANCE_TESTS } // Manueel in CI, geautomatiseerd voor CD
            }
            steps {
                script {
                    // Voer acceptatietests uit
                    sh 'dotnet test ${DOTNET_PROJECT_PATH}/Tests/AcceptanceTests'
                }
            }
        }

        stage('Generate Report') {
            steps {
                // Genereer een rapport met resultaten en beschikbaar stellen voor devs
                archiveArtifacts artifacts: 'path/to/generated/report/*', allowEmptyArchive: true
            }
        }
    }

    post {
        always {
            // Maak een rapport en verzend het resultaat naar devs
            emailext(
                to: 'dev-team@example.com',
                subject: "Build Result: ${currentBuild.fullDisplayName}",
                body: "Here is the build result: ${env.BUILD_URL}"
            )
        }
        success {
            echo 'Build succesvol afgerond!'
        }
        failure {
            echo 'Build mislukt!'
        }
    }
}

