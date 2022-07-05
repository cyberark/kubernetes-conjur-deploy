#!/usr/bin/env groovy

pipeline {
  agent { label 'executor-v2' }

  parameters {
    booleanParam(
      name: 'TEST_OCP_NEXT', defaultValue: false,
      description: 'Whether or not to run the pipeline against the next OCP version'
    )
  }

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

        stage('OpenShift Oldest 4.x') {
          steps {
            sh 'summon --environment openshift_oldest ./test.sh openshift_oldest 5'
          }
        }

        stage('OpenShift Current 4.x') {
          steps {
            sh 'summon --environment openshift_current ./test.sh openshift_current 5'
          }
        }

        stage('OpenShift Next 4.x') {
          when { expression { return params.TEST_OCP_NEXT } }
          steps {
            sh 'summon --environment openshift_next ./test.sh openshift_next 5'
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
