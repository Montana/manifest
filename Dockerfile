#!/bin/sh

IMAGE="2tefan/multiarch-test"
BASETAG="test"

case "$(arch)" in
    aarch64)
        ARCHITECTURE="s390x"
	    ;;
    x86_64)
        ARCHITECTURE="ppc64le"
        ;;
    *)
        echo "ERROR: unsupported architecture: $(arch)"
	    exit 1
	    ;;
esac

# Building & pushing to dockerhub
docker build --tag $IMAGE:$BASETAG-$ARCHITECTURE .
docker push $IMAGE:$BASETAG-$ARCHITECTURE

# Creating manifest for basetag
docker rmi $IMAGE:$BASETAG -f
docker manifest create $IMAGE:$BASETAG --amend $IMAGE:$BASETAG-amd64 --amend $IMAGE:$BASETAG-s390x

docker manifest annotate $IMAGE:$BASETAG $IMAGE:$BASETAG-$ARCHITECTURE --os linux --arch $ARCHITECTURE
docker manifest create $IMAGE:$BASETAG --amend $IMAGE:$BASETAG-amd64 --amend $IMAGE:$BASETAG-s390x
docker manifest create $IMAGE:$BASETAG --amend $IMAGE:$BASETAG-amd64 --amend $IMAGE:$BASETAG-ppc64le
docker manifest annotate $IMAGE $IMAGE:amd64 --os linux --arch amd64

docker manifest push $IMAGE:$BASETAG --purge
