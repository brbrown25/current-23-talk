#!/usr/bin/env bash
set -euo pipefail

# For publishing to the remote, the following must be set:
# export JFROG_USER=<your username>
# export JFROG_PASSWORD=<your password>
export JFROG_SERVER_ID="bbrownsound-server"
export JFROG_URL="https://bbrownsound.jfrog.io/"
export ARTIFACTORY_URL="${JFROG_URL}artifactory/"
export CI=true
export DEBUG_MODE=${DEBUG_MODE:=true}

# Required packages:
# python, golang, scala, github cli, buf cli, git, jfrog cli,

declare BASE_DIR="$(realpath $(dirname "${BASH_SOURCE[0]}"))"
declare PROTO_DIR="${BASE_DIR}/protobuf"
declare GOLANG_DIR="${BASE_DIR}/golang-protobuf-models"
declare SCALA_DIR="${BASE_DIR}/scala-protobuf-models"
declare PYTHON_DIR="${BASE_DIR}/python-protobuf-models"
declare CPP_DIR="${BASE_DIR}/cpp-protobuf-models"

export BBROWNSOUND_SCHEMAS_VERSION=$(<${PROTO_DIR}/VERSION.txt)
if [ ${PUBLISH_TYPE} != "RELEASE" ]; then
    export SCALA_BBROWNSOUND_SCHEMA_VERSION="${BBROWNSOUND_SCHEMAS_VERSION}-SNAPSHOT"
    export GOLANG_BBROWNSOUND_SCHEMA_VERSION="v${BBROWNSOUND_SCHEMAS_VERSION}-SNAPSHOT"
    # As per PEP-440: https://www.python.org/dev/peps/pep-0440/#pre-releases
    export PYTHON_BBROWNSOUND_SCHEMA_VERSION="${BBROWNSOUND_SCHEMAS_VERSION}.a"
    # Release candidtate version.
    export CPP_BBROWNSOUND_SCHEMA_VERSION="${BBROWNSOUND_SCHEMAS_VERSION}-rc"
else
    export SCALA_BBROWNSOUND_SCHEMA_VERSION="${BBROWNSOUND_SCHEMAS_VERSION}"
    export GOLANG_BBROWNSOUND_SCHEMA_VERSION="v${BBROWNSOUND_SCHEMAS_VERSION}"
    export PYTHON_BBROWNSOUND_SCHEMA_VERSION="${BBROWNSOUND_SCHEMAS_VERSION}"
    export CPP_BBROWNSOUND_SCHEMA_VERSION="${BBROWNSOUND_SCHEMAS_VERSION}"
fi

if [ ${DEBUG_MODE} != "false" ]; then
    # SCALA must end with SNAPSHOT, otherwise it's viewed as an immutable artifact
    export SCALA_BBROWNSOUND_SCHEMA_VERSION="${BBROWNSOUND_SCHEMAS_VERSION}-DEBUG-SNAPSHOT"
    export GOLANG_BBROWNSOUND_SCHEMA_VERSION="${GOLANG_BBROWNSOUND_SCHEMA_VERSION}-DEBUG"
    # As per PEP-440: https://www.python.org/dev/peps/pep-0440/#pre-releases
    export PYTHON_BBROWNSOUND_SCHEMA_VERSION="${PYTHON_BBROWNSOUND_SCHEMA_VERSION}.dev"
    # Release candidtate version.
    export CPP_BBROWNSOUND_SCHEMA_VERSION="${CPP_BBROWNSOUND_SCHEMA_VERSION}-debug"
fi

setup_artifactory_config() {
    if ! jfrog config use ${JFROG_SERVER_ID}; then
        jfrog config add ${JFROG_SERVER_ID}
        echo "added jfrog server"
        jfrog config show ${JFROG_SERVER_ID}
    fi
    export JFROG_TOKEN=$(jfrog rt access-token-create --server-id bbrownsound-server | jq -r ".access_token")
}

# There is no required build step for Golang
build_golang() {
    :
}

# Golang can be imported into other project without an explicit publish step.
# https://golang.org/doc/modules/managing-dependencies#unpublished
publish_golang_locally() {
    :
}

publish_golang_to_remote() {
    cd ${GOLANG_DIR}
    echo "Publishing ${GOLANG_BBROWNSOUND_SCHEMA_VERSION} of Golang package to remote"
    if ! jfrog config use ${JFROG_SERVER_ID}; then
        jfrog config add ${JFROG_SERVER_ID} --url ${JFROG_URL} --user ${JFROG_USER} --password ${JFROG_PASSWORD}
        echo "added jfrog server"
        jfrog config show ${JFROG_SERVER_ID}
    fi
    jfrog rt gp ${GOLANG_BBROWNSOUND_SCHEMA_VERSION}
    cd ${BASE_DIR}
}

# The build step is included in sbt's publish command.
build_scala() {
    :
}

publish_scala_locally() {
    cd ${SCALA_DIR}
    echo "Publishing version ${SCALA_BBROWNSOUND_SCHEMA_VERSION} of Scala package locally"
    sbt +publishLocal
    cd ${BASE_DIR}
}

publish_scala_to_remote() {
    cd ${SCALA_DIR}
    echo "Publishing version ${SCALA_BBROWNSOUND_SCHEMA_VERSION} of Scala package to remote"
    sbt +publish
    cd ${BASE_DIR}
}

# Required packages: twine, build
build_python() {
    cd ${PYTHON_DIR}
    rm -rf src/python_protobuf_models.egg_info
    rm -rf dist/*
    python3 -m build --sdist --wheel .
    cd ${BASE_DIR}
}

publish_python_locally() {
    cd ${PYTHON_DIR}
    echo "Publishing version ${PYTHON_BBROWNSOUND_SCHEMA_VERSION} of Python package locally"
    python3 -m pip install --use-feature=fast-deps .
    cd ${BASE_DIR}
}

publish_python_to_remote() {
    build_python
    cd ${PYTHON_DIR}
    echo "Publishing version ${PYTHON_BBROWNSOUND_SCHEMA_VERSION} of Python package to remote"
    python3 -m twine upload --repository-url "${ARTIFACTORY_URL}api/pypi/ssc-pypi-local" -u ${JFROG_USER} -p ${JFROG_PASSWORD} dist/*
    cd ${BASE_DIR}
}

cpp_conan_profile_setup() {
    if ! conan profile list | grep -q default -; then
        conan profile new default --detect
    fi

    conan profile update settings.compiler.libcxx=libc++ default
    conan profile update settings.compiler.version=14.0 default
    conan profile update settings.os=Macos default
    conan profile update settings.arch=armv8 default
}

publish_cpp_locally() {
    cpp_conan_profile_setup
    cd ${CPP_DIR}
    rm -rf build
    # Conan create will reference the local cache instance, so we cannot use that command when doing local builds.
    conan install . --build=missing --install-folder build/
    conan source . --source-folder build/
    conan build . --source-folder build/ --build-folder build/
    conan package . --source-folder build/ --build-folder build/ --package-folder protobuf-models

    cd ${BASE_DIR}
}

publish_cpp_to_remote() {
    cpp_conan_profile_setup
    cd ${CPP_DIR}

    rm -rf build

    if ! conan remote list | grep -q ssc-conan -; then
        conan remote add ssc-conan ${ARTIFACTORY_URL}api/conan/ssc-conan-local
        conan user -p ${JFROG_PASSWORD} -r ssc-conan ${JFROG_USER}
    fi

    conan create . protobuf-models/${CPP_BBROWNSOUND_SCHEMA_VERSION}@

    echo "Publishing version ${CPP_BBROWNSOUND_SCHEMA_VERSION} of C++ package to remote"
    conan upload protobuf-models/${CPP_BBROWNSOUND_SCHEMA_VERSION}@ --force --all -r=ssc-conan --check --confirm
    cd ${BASE_DIR}
}

publish_all_to_remote() {
    if [ ${PUBLISH_TYPE} != "RELEASE" ]; then
        echo "Publishing SNAPSHOT version ${BBROWNSOUND_SCHEMAS_VERSION} of schema library to remote"
    else
        echo "Publishing RELEASE version ${BBROWNSOUND_SCHEMAS_VERSION} of schema library to remote"
    fi
    publish_python_to_remote
    publish_golang_to_remote
    publish_scala_to_remote
    publish_cpp_to_remote
}

publish_all_locally() {
    if [ ${PUBLISH_TYPE} != "RELEASE" ]; then
        echo "Publishing SNAPSHOT version ${BBROWNSOUND_SCHEMAS_VERSION} of schema library locally"
    else
        echo "Publishing RELEASE version ${BBROWNSOUND_SCHEMAS_VERSION} of schema library locally"
    fi
    publish_golang_locally
    publish_python_locally
    publish_scala_locally
    publish_cpp_locally
}

check_uncommitted() {
    echo -n "Checking if there are uncommited changes... "
    trap 'echo -e "\033[0;31mFAILED\033[0m"' ERR
    git diff-index --quiet HEAD --
    trap - ERR
    echo -e "\033[0;32mAll set!\033[0m"
}

update_production_branch() {
    git checkout production
    git pull origin production
    git checkout -
}

open_pr() {
    check_uncommitted
    update_production_branch
    CURR_MAJOR=${BBROWNSOUND_SCHEMAS_VERSION%%\.*}
    PROD_VERSION=$(git show production:${PROTO_DIR}/VERSION.txt)
    PROD_MAJOR=${PROD_VERSION%%\.*}

    if [ ${CURR_MAJOR} -gt ${PROD_MAJOR} ]; then
        gh pr create -B main
    elif [ ${CURR_MAJOR} -eq ${PROD_MAJOR} ]; then
        buf breaking --against 'https://github.com/brbrown25/current-23-talk.git#branch=production,subdir=protobuf'
        if [ ${BBROWNSOUND_SCHEMAS_VERSION} -eq ${PROD_VERSION} ]; then
            # Diffing protobuf directory also diffs VERSION file, but that's fine.
            # We just don't want no change in VERSION & change in proto directory.
            if [!git diff --quiet production HEAD -- protobuf]; then
                echo "Change detected in protobuf directory, but VERSION.txt not changed!"
                exit 1
            fi
        fi
    else
        echo "Current version must be greater than or equal to production version!"
        exit 1
    fi
}

if declare -f "$1" > /dev/null
then
  # call arguments verbatim
  "$@"
else
  # Show a helpful error
  echo "'$1' is not a known function name" >&2
  exit 1
fi
