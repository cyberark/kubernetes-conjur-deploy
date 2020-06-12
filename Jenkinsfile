#!/usr/bin/env groovy

pipeline {
  agent { label 'executor-v2' }

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '30'))
  }

  triggers {
    cron(getDailyCronString())
  }

  stages {
    stage('Run Scripts') {
      parallel {
        stage('Test on OpenShift 4.3 in AWS') {
          steps {
            sh 'summon --environment openshift43 ./test.sh openshift43 5'
          }
        }
      }
      post { always {
        archiveArtifacts artifacts: 'output/*'
      }}
    }
  }

  post {
    always {
      cleanupAndNotify(currentBuild.currentResult)
    }
  }
}
