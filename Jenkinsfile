def customImage = ''

pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                echo 'Building...'

                script {
                    customImage = docker.build("my-image:${env.BUILD_ID}", "-f ./docker/images/web_live/Dockerfile .")
                }
            }
        }
        stage('Test') {
            steps {
                echo 'Testing...'

                script {
                    customImage.inside {
                        sh 'cat readme.md'
                    }
                }
            }
        }
        stage('Push') {
            steps {
                echo 'Pushing...'

                customImage.push('latest')
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying...'
            }
        }
    }
}
