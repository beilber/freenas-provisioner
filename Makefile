BIN=bin

IMAGE_NAME=freenas-provisioner
IMAGE_VERSION=2.4
REMOTE_NAME=$(DOCKER_ID_USER)/$(IMAGE_NAME)

.PHONY: all
all: build

.PHONY: fmt
fmt:
	go fmt ./...

tmp:
	mkdir -p tmp/

$(BIN):
	mkdir -p $(BIN)

.PHONY: image
image: tmp check-docker-hub
	cp bin/freenas-provisioner tmp/ && \
		chmod +x tmp/freenas-provisioner
	docker build -t $(IMAGE_NAME):$(IMAGE_VERSION) -f Dockerfile.alpine .

.PHONY: tag
tag: image
	docker tag $(IMAGE_NAME):$(IMAGE_VERSION) $(REMOTE_NAME):$(IMAGE_VERSION)

.PHONY: push
push: tag
	docker push $(REMOTE_NAME):$(IMAGE_VERSION)

vendor:
	dep ensure

.PHONY: build
$(BIN)/freenas-provisioner build: vendor $(BIN) $(shell find . -name "*.go")
	env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -v -a -ldflags '-extldflags "-static"' -o $(BIN)/freenas-provisioner .

.PHONY: darwin
$(BIN)/freenas-provisioner-darwin darwin: vendor $(BIN) $(shell find . -name "*.go")
	env CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -v -a -ldflags '-extldflags "-static"' -o $(BIN)/freenas-provisioner-darwin .

.PHONY: freebsd
$(BIN)/freenas-provisioner-freebsd freebsd: vendor $(BIN) $(shell find . -name "*.go")
	env CGO_ENABLED=0 GOOS=freebsd GOARCH=amd64 go build -v -a -ldflags '-extldflags "-static"' -o $(BIN)/freenas-provisioner-freebsd .

.PHONY: clean
clean:
	go clean -i
	rm -rf $(BIN)
	rm -rf tmp
	rm -rf vendor

.PHONY: check-docker-hub
check-docker-hub:
ifndef DOCKER_ID_USER
	$(error ERROR! DOCKER_ID_USER environment variable must be defined)
endif
