
#!/bin/sh

IMAGE="2tefan/multiarch-test"
BASETAG="test"

case "$(arch)" in
    aarch64)
        ARCHITECTURE="arm64"
	    ;;
    x86_64)
        ARCHITECTURE="amd64"
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
docker manifest create $IMAGE:$BASETAG --amend $IMAGE:$BASETAG-amd64 --amend $IMAGE:$BASETAG-arm64

docker manifest annotate $IMAGE:$BASETAG $IMAGE:$BASETAG-$ARCHITECTURE --os linux --arch $ARCHITECTURE
# docker manifest annotate $IMAGE $IMAGE:amd64 --os linux --arch amd64
# docker manifest annotate $IMAGE $IMAGE:arm64 --os linux --arch arm64

docker manifest push $IMAGE:$BASETAG --purge
