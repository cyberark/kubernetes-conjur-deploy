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
        stage('Test v4 on K8S 1.7 in GKE') {
          steps {
            sh 'sleep 15'  // sleep 15s to avoid script collisions
            sh 'summon ./test.sh gke 4'
          }
        }
        stage('Test v5 on K8S 1.7 in GKE') {
          steps {
            sh 'summon ./test.sh gke 5'
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
