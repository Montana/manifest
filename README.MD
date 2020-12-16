# Manifest with Travis CI 

First thing is you'll need to set your `docker env vars`, you can do this by once the repo is created, along with your `.travis.yml` and your `Dockerfile` you can login into Travis from the CLI via:

```bash
travis login --pro
```

## Setting up env vars

You can use your GitHub auth token, or just username/password, once logged in set the `env vars`: 

```bash
travis env set DOCKER_USERNAME username
travis env set DOCKER_PASSWORD pwd
```

That will now set both your Docker username/password as env vars. 

## Manifest

In your Dockerfile, do the classic configurations, then you'll want to add (if you want to build s390x, ppc64le): 

```Dockerfile
# you're building & pushing to dockerhub in my case montanamendy is pushing 
docker build --tag $IMAGE:$BASETAG-$ARCHITECTURE .
docker push $IMAGE:$BASETAG-$ARCHITECTURE

# this in particular is for creating manifest for basetag
docker rmi $IMAGE:$BASETAG -f
docker manifest create $IMAGE:$BASETAG --amend $IMAGE:$BASETAG-amd64 --amend $IMAGE:$BASETAG-s390x

docker manifest annotate $IMAGE:$BASETAG $IMAGE:$BASETAG-$ARCHITECTURE --os linux --arch $ARCHITECTURE
docker manifest create $IMAGE:$BASETAG --amend $IMAGE:$BASETAG-amd64 --amend $IMAGE:$BASETAG-s390x
docker manifest create $IMAGE:$BASETAG --amend $IMAGE:$BASETAG-amd64 --amend $IMAGE:$BASETAG-ppc64le
docker manifest annotate $IMAGE $IMAGE:amd64 --os linux --arch amd64

docker manifest push $IMAGE:$BASETAG --purge
```

More info on [docker manifest](https://docs.docker.com/engine/reference/commandline/manifest/).
