#!/usr/bin/env bash

DEST_IMAGE="quay.io/example/scorecard-proxy"
CSV_PATH="deploy/olm-catalog/memcached-operator/0.0.3/memcached-operator.v0.0.3.clusterserviceversion.yaml"
CONFIG_PATH=".test-osdk-scorecard.yaml"

set -ex

# build scorecard-proxy image (and delete intermediate builder image)
./hack/image/build-scorecard-proxy-image.sh "$DEST_IMAGE"

# the test framework directory has all the manifests needed to run the cluster
pushd test/test-framework
commandoutput="$(operator-sdk scorecard \
  --cr-manifest deploy/crds/cache_v1alpha1_memcached_cr.yaml \
  --cr-manifest deploy/crds/cache_v1alpha1_memcachedrs_cr.yaml \
  --init-timeout 60 \
  --csv-path "$CSV_PATH" \
  --verbose \
  --proxy-image "$DEST_IMAGE" \
  --proxy-pull-policy Never \
  2>&1)"
echo $commandoutput | grep "Total Score: 87%"

# test config file
commandoutput2="$(operator-sdk scorecard \
  --proxy-image "$DEST_IMAGE" \
  --config "$CONFIG_PATH")"
# check basic suite
echo $commandoutput2 | grep '^.*"error": 0,[[:space:]]"pass": 3,[[:space:]]"partialPass": 0,[[:space:]]"fail": 0,[[:space:]]"totalTests": 3,[[:space:]]"totalScorePercent": 100,.*$'
# check olm suite
echo $commandoutput2 | grep '^.*"error": 0,[[:space:]]"pass": 2,[[:space:]]"partialPass": 3,[[:space:]]"fail": 0,[[:space:]]"totalTests": 5,[[:space:]]"totalScorePercent": 74,.*$'
popd
