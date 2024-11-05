def sendDiscordNotification(status) {
    script {
        // Combine Git commands into one sh block without printing sensitive info
        def gitInfo = sh(script: '''
            AUTHOR_NAME=$(git show -s HEAD --pretty=format:"%an")
            AUTHOR_EMAIL=$(git show -s HEAD --pretty=format:"%ae")
            COMMIT_MESSAGE=$(git show -s HEAD --pretty=format:"%s")
            GIT_COMMIT=$(git rev-parse HEAD)
            GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
            echo "$AUTHOR_NAME;$AUTHOR_EMAIL;$COMMIT_MESSAGE;$GIT_COMMIT;$GIT_BRANCH"
        ''', returnStdout: true).trim().split(";")

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
