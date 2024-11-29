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
        JENKINS_CREDENTIALS_ID = "jenkins-master-key"
        SSH_KEY_FILE = '/var/lib/jenkins/.ssh/id_rsa'
        REMOTE_HOST = 'jenkins@172.16.128.101'
        COVERAGE_REPORT_PATH = '/var/lib/jenkins/agent/workspace/dotnet_pipeline/coverage/coverage.cobertura.xml'
        COVERAGE_REPORT_DIR = '/var/lib/jenkins/agent/workspace/dotnet_pipeline/coverage-report/'
        TRX_FILE_PATH = 'p3ops-demo-app/tests/Domain.Tests/TestResults/test-results.trx'
        TEST_RESULT_PATH = 'p3ops-demo-app/tests/Domain.Tests/TestResults'
        TRX_TO_XML_PATH = 'p3ops-demo-app/tests/Domain.Tests/TestResults/test-results.xml'
        PUBLISH_DIR_PATH = '/var/lib/jenkins/artifacts/'
        JENKINS_SERVER = 'http://139.162.132.174:8080'
        DOTNET_TEST_PATH = 'Rise.Domain.Tests/Rise.Domain.Tests.csproj'
        REPO_OWNER = "Brahim-Mahfoudhi"
        REPO_NAME = "p3ops-demo-app"
        GIT_BRANCH = env.CHANGE_BRANCH ?: 
        DISCORD_WEBHOOK_URL = "https://discord.com/api/webhooks/1301160382307766292/kROxjtgZ-XVOibckTMri2fy5-nNOEjzjPLbT9jEpr_R0UH9JG0ZXb2XzUsYGE0d3yk6I"

    }
       
    parameters {
        string(name: 'sha1', defaultValue: '', description: 'Commit SHA1')
    }

    stages {
        stage('Check for Pull Request') {
            steps {
                script {
                    if (!env.CHANGE_ID) {
                        echo "This build is not triggered by a Pull Request. Skipping the pipeline."
                        currentBuild.result = 'ABORTED'
                        return
                    }
                }
            }
        }

        stage('Checkout PR') {
            steps {
                script {
                    echo "Checking out Pull Request: ${env.CHANGE_ID} from branch ${env.CHANGE_BRANCH}"
                    sh """
                        git fetch origin pull/${env.CHANGE_ID}/head:pr/${env.CHANGE_ID}
                        git checkout pr/${env.CHANGE_ID}
                    """
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

        stage('Running Unit Tests') {
            steps {
                sh "dotnet test ${DOTNET_TEST_PATH} --logger 'trx;LogFileName=test-results.trx' /p:CollectCoverage=true /p:CoverletOutput=${COVERAGE_REPORT_PATH} /p:CoverletOutputFormat=cobertura"
            }
        }

        stage('Coverage Report') {
            steps {
                echo 'Generating code coverage report...'
                script {
                    sh "/home/jenkins/.dotnet/tools/reportgenerator -reports:${COVERAGE_REPORT_PATH} -targetdir:${COVERAGE_REPORT_DIR} -reporttypes:Html"
                    publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: true, reportDir: COVERAGE_REPORT_DIR, reportFiles: 'index.html', reportName: 'Coverage Report'])
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
                
                [**Build output**](http://172.16.128.100:8080/job/${env.JOB_NAME}/${env.BUILD_NUMBER}/console) - Build output
                [**Test result**](http://172.16.128.100:8080/job/dotnet_pipeline/lastBuild/testReport/) - Test result
                [**Coverage report**](http://172.16.128.100:8080/job/dotnet_pipeline/lastBuild/Coverage_20Report/) - Coverage report
                [**History**](http://172.16.128.100:8080/job/dotnet_pipeline/${env.BUILD_NUMBER}/testReport/history/) - History
            """,
            footer: "Build Duration: ${currentBuild.durationString.replace(' and counting', '')}",
            webhookURL: DISCORD_WEBHOOK_URL,
            result: status == "Build Success" ? 'SUCCESS' : 'FAILURE'
        )
    }
}
