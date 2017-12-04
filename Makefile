VERSION ?= 0.3.0
CACHE ?= --no-cache=1
FULLVERSION ?= ${VERSION}
archs = amd64 arm32v6 arm64v8 i386

.PHONY: all build publish latest
all: build publish latest
build:
	cp /usr/bin/qemu-*-static .
	$(foreach arch,$(archs), \
		a=$$(echo $(arch) | awk -F"arm" '{print $$2}'); \
		cat Dockerfile.builder > Dockerfile; \
		if [ "$$a" = "" ]; then \
			cat Dockerfile.amd | sed "s/FROM alpine/FROM $(arch)\/alpine/g" >> Dockerfile; \
			cat Dockerfile.common >> Dockerfile; \
			docker build -t jaymoulin/plex:${VERSION}-$(arch) --build-arg ARM=0 ${CACHE} .;\
		else \
			cat Dockerfile.arm >> Dockerfile; \
			cat Dockerfile.common >> Dockerfile; \
			docker build -t jaymoulin/plex:${VERSION}-$(arch) ${CACHE} .;\
		fi; \
	)
publish:
	docker push jaymoulin/plex
	cat manifest.yml | sed "s/\$$VERSION/${VERSION}/g" > manifest.yaml
	cat manifest.yaml | sed "s/\$$FULLVERSION/${FULLVERSION}/g" > manifest2.yaml
	mv manifest2.yaml manifest.yaml
	manifest-tool push from-spec manifest.yaml
latest: build
	FULLVERSION=latest VERSION=${VERSION} make publish