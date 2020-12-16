#!/bin/sh

IMAGE="2tefan/multiarch-test"
BASETAG="test"

arch_to_image() {
	case $1 in
		x86_64) echo amd64 ;;
		ppc64le) echo ppc64le ;;
		s390x) echo s390x ;;
		*) die "Unknown arch detected: \"$1\""
	esac
}

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
