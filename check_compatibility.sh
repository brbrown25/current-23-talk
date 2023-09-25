#!/usr/bin/env bash
set -euo pipefail

if ! [ -n "${CI:-}" ]; then
    echo "Not running in CI. Downloading current production version for comparison"
    rm -rf production_ver
    git clone --branch production 'ssh://git@github.com/brbrown28/current-23-talk.git' production_ver
fi

declare BASE_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
declare PROTO_DIR="${BASE_DIR}/protobuf"
export BBROWNSOUND_SCHEMAS_VERSION=$(<${PROTO_DIR}/VERSION.txt)

CURR_MAJOR=${BBROWNSOUND_SCHEMAS_VERSION%%\.*}
PROD_VERSION=$(<production_ver/protobuf/VERSION.txt)
PROD_MAJOR=${PROD_VERSION%%\.*}

if [ ${CURR_MAJOR} -gt ${PROD_MAJOR} ]; then
    exit 0
elif [ ${CURR_MAJOR} -eq ${PROD_MAJOR} ]; then
    # export BUF_CACHE_DIR="${BASE_DIR}"
    cd "protobuf"
    buf breaking --against "${BASE_DIR}/production_ver/protobuf" --config "${BASE_DIR}/buf.yaml"
    cd "${BASE_DIR}"
    if [ ${BBROWNSOUND_SCHEMAS_VERSION} = ${PROD_VERSION} ]; then
        # Diffing protobuf directory also diffs VERSION file, but that's fine.
        # We just don't want no change in VERSION & change in proto directory.
        if ! git diff --no-index --quiet production_ver/protobuf protobuf; then
            echo "Change detected in protobuf directory, but VERSION.txt not changed!"
            exit 1
        fi
    fi
else
    echo "Current version must be greater than or equal to production version!"
    exit 1
fi

echo "compatibility check complete!"
exit 0
