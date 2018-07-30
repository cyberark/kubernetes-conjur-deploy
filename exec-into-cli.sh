#!/bin/bash
. ./utils.sh
set_namespace $CONJUR_NAMESPACE_NAME
conjur_cli_pod=$(get_conjur_cli_pod_name)
$cli exec -it $conjur_cli_pod -- bash
set_namespace $TEST_APP_NAMESPACE_NAME
