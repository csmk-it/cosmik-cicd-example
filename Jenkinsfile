pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                echo 'Building..'

                script {
                    def customImage = docker.build("my-image:${env.BUILD_ID}", "-f ./docker/images/web_live/Dockerfile .")
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
