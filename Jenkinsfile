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
        stage('Test on K8S 1.7 in GKE') {
          steps {
            sh 'summon ./test.sh gke'
          }
        }
        stage('Test on OpenShift 3.3 in AWS') {
          steps {
            sh 'summon -e openshift33 ./test.sh openshift33'
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
