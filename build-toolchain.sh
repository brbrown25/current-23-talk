# v1.58.1
export GRPC_VERSION="1.54.0"
export GRPC_JAVA_VERSION="1.54.0"
export GRPC_WEB_VERSION="1.4.2"
export OMNIPROTO_TOOLS_BUILD_VERSION="1"
export BUF_VERSION="1.16.0"
export BUILD_VERSION="${GRPC_VERSION}_${OMNIPROTO_TOOLS_BUILD_VERSION}"
export SCALA_PB_VERSION="0.11.13"
export LIB_PROTOC_VERSION="22.2"

TOOLS=(grpckit protoc buf omniproto)

for tool in ${TOOLS[@]}; do
  BUILD_TAG="grpckit/${tool}:${BUILD_VERSION}"
  echo "building ${tool} container with tag ${BUILD_TAG}"
  docker build -t ${BUILD_TAG} \
    --file GrpcKitToolsDockerfile \
    --build-arg libprotoc_version=${LIB_PROTOC_VERSION} \
    --build-arg grpc=${GRPC_VERSION} \
    --build-arg grpc_java=${GRPC_JAVA_VERSION} \
    --build-arg grpc_web=${GRPC_WEB_VERSION} \
    --build-arg buf_version=${BUF_VERSION} \
    --build-arg scalapb_version=${SCALA_PB_VERSION} \
    --target ${tool} \
    .
done;
