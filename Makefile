.PHONY: generate

# Make sure this matches with the python out directory in omniproto.yaml
PYTHON_PROTO_PATH="python-protobuf-models/src/bbrownsound"

generate-local:
	docker run --rm -v `pwd`:/workspace grpckit/omniproto:1.54.0_1
	#Fix the import path for nested packages
	find $(PYTHON_PROTO_PATH) -type f -print0 | xargs -0 -I{} sed -i '' 's/from com/from bbrownsound.com/' "{}"
	#Add the __init__.py that is needed for modules to work
	find $(PYTHON_PROTO_PATH) -type d -exec touch {}/__init__.py \;

lint:
	docker run --rm --entrypoint="" -v `pwd`:/workspace grpckit/buf:1.54.0_1 /bin/bash -c 'cd protobuf && buf lint --config ../buf.yaml'

compatibility-check:
	rm -rf production_ver && git clone --branch production https://github.com/brbrown25/current-23-talk.git production_ver
	docker run --rm --entrypoint="" -v `pwd`:/workspace grpckit/buf:1.54.0_1 /bin/bash -c 'cd protobuf && buf breaking --against "../production_ver/protobuf" --config "../buf.yaml"'

publish-local-snapshot:
	export PUBLISH_TYPE=SNAPSHOT && ./deploy.sh publish_all_locally
