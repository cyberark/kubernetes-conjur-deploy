#!/usr/bin/env groovy

pipeline {
  agent { label 'conjur-enterprise-common-agent' }

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
    stage('Get InfraPool Agent') {
      steps {
        script {
          INFRAPOOL_EXECUTORV2_AGENT_0 = getInfraPoolAgent.connected(type: "ExecutorV2", quantity: 1, duration: 1)[0]
        }
      }
    }

    stage('Run Scripts') {
      parallel {
        stage('Test on GKE') {
          steps {
            script {
              INFRAPOOL_EXECUTORV2_AGENT_0.agentSh 'summon --environment kubernetes ./test.sh gke'
            }
          }
        }

        stage('OpenShift Oldest 4.x') {
          steps {
            script {
              INFRAPOOL_EXECUTORV2_AGENT_0.agentSh 'summon --environment openshift_oldest ./test.sh openshift_oldest'
            }
          }
        }

        stage('OpenShift Current 4.x') {
          steps {
            script {
              INFRAPOOL_EXECUTORV2_AGENT_0.agentSh 'summon --environment openshift_current ./test.sh openshift_current'
            }
          }
        }

        stage('OpenShift Next 4.x') {
          when { expression { return params.TEST_OCP_NEXT } }
          steps {
            script {
              INFRAPOOL_EXECUTORV2_AGENT_0.agentSh 'summon --environment openshift_next ./test.sh openshift_next'
            }
          }
        }
      }

      post { always {
        script {
          INFRAPOOL_EXECUTORV2_AGENT_0.agentArchiveArtifacts artifacts: 'output/*'
        }
      }}
    }
  }

  post {
    always {
      releaseInfraPoolAgent(".infrapool/release_agents")
    }
  }
}
