def customImage = ''

pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                echo 'Building..'

                script {
                    customImage = docker.build("my-image:${env.BUILD_ID}", "-f ./docker/images/web_live/Dockerfile .")
                    // customImage.push('latest')
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
