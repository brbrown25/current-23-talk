# current-23-talk
Holding slides and examples for my Confluent Current23 talk

# Build the toolchain
```shell
./build-toolchain.sh
```

# Generate the classes
```shell
make generate-local
```

# Publish Libraries locally
```shell
conda activate current23
make publish-local-snapshot
```
