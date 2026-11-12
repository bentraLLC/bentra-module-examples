# Build the binaries the runner executes. Commit bin/: Bentra packages what is in the repository.
PLATFORMS := linux-amd64 linux-arm64

.PHONY: build
build: $(PLATFORMS:%=bin/%/sha-tool)

bin/%/sha-tool: src/main.go src/go.mod
	cd src && CGO_ENABLED=0 GOOS=$(word 1,$(subst -, ,$*)) GOARCH=$(word 2,$(subst -, ,$*)) \
		go build -trimpath -ldflags="-s -w -buildid=" -o ../$@ .
