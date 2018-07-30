#!/usr/bin/env groovy

pipeline {
  agent { label 'executor-v2' }

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '30'))
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
        /*
        stage('Test on OpenShift 3.7 in AWS') {
          steps {
            sh 'summon -e openshift37 ./test.sh openshift37'
          }
        }
        */
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
