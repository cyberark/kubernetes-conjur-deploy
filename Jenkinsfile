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
        stage('Test v5 on GKE') {
          steps {
            sh 'summon --environment kubernetes ./test.sh gke 5'
          }
        }
        stage('Test on OpenShift 3.9 in AWS') {
          steps {
            sh 'summon --environment openshift39 ./test.sh openshift39 5'
          }
        }
        stage('Test on OpenShift 3.10 in AWS') {
          steps {
            sh 'summon --environment openshift310 ./test.sh openshift310 5'
          }
        }
        stage('Test on OpenShift 3.11 in AWS') {
          steps {
            sh 'summon --environment openshift311 ./test.sh openshift311 5'
          }
        }
        stage('Test on OpenShift 4.1 in AWS') {
          steps {
            sh 'summon --environment openshift41 ./test.sh openshift41 5'
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
