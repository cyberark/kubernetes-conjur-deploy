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
        stage('Test on OpenShift 3.11 in AWS') {
          steps {
            sh 'summon --environment openshift311 ./test.sh openshift311 5'
          }
        }
        stage('Test on OpenShift 4.3 in AWS') {
          steps {
            sh 'summon --environment openshift43 ./test.sh openshift43 5'
          }
        }
        stage('Test on OpenShift 4.3-fips in AWS') {
         steps {
           sh 'summon --environment openshift43-fips ./test.sh openshift43-fips 5'
         }
        }
        stage('Test on current OpenShift in AWS') {
          steps {
            sh 'summon --environment openshift_current ./test.sh openshift_current 5'
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
