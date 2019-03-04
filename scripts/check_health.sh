#!/bin/bash
# uncomment to debug the script
# set -x
# copy the script below into your app code repo (e.g. ./scripts/check_health.sh) and 'source' it from your pipeline job
#    source ./scripts/check_health.sh
# alternatively, you can source it from online script:
#    source <(curl -sSL "https://raw.githubusercontent.com/open-toolchain/commons/master/scripts/check_health.sh")
# ------------------
# source: https://raw.githubusercontent.com/open-toolchain/commons/master/scripts/check_health.sh
# Check liveness and readiness probes to confirm application is healthy
# Input env variables (can be received via a pipeline environment properties.file.
echo "IMAGE_NAME=${IMAGE_NAME}"
echo "IMAGE_TAG=${IMAGE_TAG}"
echo "REGISTRY_URL=${REGISTRY_URL}"
echo "REGISTRY_NAMESPACE=${REGISTRY_NAMESPACE}"
echo "CLUSTER_NAMESPACE=${CLUSTER_NAMESPACE}"

IMAGE_REPOSITORY=${REGISTRY_URL}/${REGISTRY_NAMESPACE}/${IMAGE_NAME}

CONTAINERS_JSON=$(kubectl get deployments --namespace ${CLUSTER_NAMESPACE} -o json | jq -r ".items[].spec.template.spec.containers[]? | select(.image==\"${IMAGE_REPOSITORY}:${IMAGE_TAG}\") ")
echo $CONTAINERS_JSON | jq .

LIVENESS_PROBE_PATH=$(echo $CONTAINERS_JSON | jq -r ".livenessProbe.httpGet.path" | head -n 1)
# LIVENESS_PROBE_PORT=$(echo $CONTAINERS_JSON | jq -r ".livenessProbe.httpGet.port" | head -n 1)
if [ ${LIVENESS_PROBE_PATH} != null ]; then
  LIVENESS_PROBE_URL=${APP_URL}${LIVENESS_PROBE_PATH}
  if [ "$(curl -Is ${LIVENESS_PROBE_URL} --connect-timeout 3 --max-time 5 --retry 2 --retry-max-time 30 | head -n 1 | grep 200)" != "" ]; then
    echo "Successfully reached liveness probe endpoint: ${LIVENESS_PROBE_URL}"
    echo "====================================================================="
  else
    echo "Could not reach liveness probe endpoint: ${LIVENESS_PROBE_URL}"
    exit 1;
  fi
else
  echo "No liveness probe endpoint defined (should be specified in deployment resource."
fi

READINESS_PROBE_PATH=$(echo $CONTAINERS_JSON | jq -r ".readinessProbe.httpGet.path" | head -n 1)
# READINESS_PROBE_PORT=$(echo $CONTAINERS_JSON | jq -r ".readinessProbe.httpGet.port" | head -n 1)
if [ ${READINESS_PROBE_PATH} != null ]; then
  READINESS_PROBE_URL=${APP_URL}${READINESS_PROBE_PATH}
  if [ "$(curl -Is ${READINESS_PROBE_URL} --connect-timeout 3 --max-time 5 --retry 2 --retry-max-time 30 | head -n 1 | grep 200)" != "" ]; then
    echo "Successfully reached readiness probe endpoint: ${READINESS_PROBE_URL}"
    echo "====================================================================="
  else
    echo "Could not reach readiness probe endpoint: ${READINESS_PROBE_URL}"
    exit 1;
  fi
else
  echo "No readiness probe endpoint defined (should be specified in deployment resource."
fi
