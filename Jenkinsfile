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
          post {
            always {
              junit 'output/*.xml'
              archiveArtifacts artifacts: 'output/gke-kubernetes-conjur-deploy-logs.txt'
            }
          }
        }
        stage('Test on OpenShift 3.3 in AWS') {
          steps {
            sh 'summon -e openshift33 ./test.sh openshift33'
          }
          post {
            always {
              junit 'output/*.xml'
              archiveArtifacts artifacts: 'output/openshift33-kubernetes-conjur-deploy-logs.txt'
            }
          }
        }
        stage('Test on OpenShift 3.7 in AWS') {
          steps {
            sh 'summon -e openshift37 ./test.sh openshift37'
          }
          post {
            always {
              junit 'output/*.xml'
              archiveArtifacts artifacts: 'output/openshift37-kubernetes-conjur-deploy-logs.txt'
            }
          }
        }
      }
    }
  }

  post {
    always {
      cleanupAndNotify(currentBuild.currentResult)
    }
  }
}
