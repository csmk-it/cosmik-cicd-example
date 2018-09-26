pipeline {
    agent any

    stages {
        def customImage

        stage('Build') {
            steps {
                echo 'Building..'

                script {
                    customImage = docker.build("my-image:${env.BUILD_ID}", "-f ./docker/images/web_live/Dockerfile .")
                    // customImage.push()
                }
            }
        }
        stage('Test') {
            steps {
                echo 'Testing..'

                script {
                    customImage.inside {
                        cat readme.md
                    }
                }
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying....'
            }
        }
    }
}
