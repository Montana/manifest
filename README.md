![Header](header.png)

[![Build Status](https://travis-ci.com/Montana/dat-manifest.svg?branch=master)](https://travis-ci.com/Montana/dat-manifest)

# Manifest with Travis CI 

First thing, you'll need to set your `docker env vars`, you can do this once the repo is created, along with your `.travis.yml` and your `Dockerfile` you can login into Travis from the CLI via:

```bash
travis login --pro --github-token (your github token) 
```

Then just to make sure you're logged into the proper Travis CI account run: 

```bash
travis whatsup
```

It's my own personal opinion, when pushing for `manifests` you should always commit with `-asm` so you're signing off on it so, instead of the regular `git commit -m "whatever"` you'd run `git commit -asm "whatever"`. In this particular example, I grabbed from the `Docker Hub` the following package: 

```bash
lucashalbert/curl
```

This is the perfect package (`cURL`) to show a multiarch docker image using `ppc64le`, `s390x`, and it's manifests.

## Docker configuration files 

By default, the Docker command line stores its configuration files in a directory called `.docker` within your `$HOME` directory, this can obviously be changed, but for now we are talking by standard practices. 

Docker manages most of the files in the configuration directory and you should **not modify** them. However, you can modify the `config.json` file to control certain aspects of how the docker command behaves, (e.g. flags, manifest, etc). 

You can modify the docker command behavior using `environment variables`, you'll see me use the term `env vars` (it's the same meaning), or CLI options. You can also use options within `config.json` to modify some of the same exact behavior. If an `env var` and the --config flag are set, the flag takes precedent over the `env var`. CLI options override `env vars` and `env vars` override properties you specify in a `config.json` file. It's a bit of give and take. 

Overriding a single value in your `.env` file is reasonably simple: just set an `env var` with the same name in your shell before rerunning docker.

### Change the `.docker` directory

You can close out docker, reopen terminal and run: 

```bash
docker --config ~/testconfigs/ ps
```

This particular flag only applies to whatever command is being called. For persistent config, you can set the `DOCKER_CONFIG` `env var` in your shell (e.g. ~/.profile or ~/.bashrc)(Between `zsh`, `bashrc`). The example below sets the new directory to be `HOME/newdir/.docker.`:

```bash
echo export DOCKER_CONFIG=$HOME/newdir/.docker > ~/.profile
```

### Sample docker `config.json` file

Following is a sample `config.json` file:


```json
{
  "HttpHeaders": {
    "MyHeader": "MyValue"
  },
  "psFormat": "table {{.ID}}\\t{{.Image}}\\t{{.Command}}\\t{{.Labels}}",
  "imagesFormat": "table {{.ID}}\\t{{.Repository}}\\t{{.Tag}}\\t{{.CreatedAt}}",
  "pluginsFormat": "table {{.ID}}\t{{.Name}}\t{{.Enabled}}",
  "statsFormat": "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}",
  "servicesFormat": "table {{.ID}}\t{{.Name}}\t{{.Mode}}",
  "secretFormat": "table {{.ID}}\t{{.Name}}\t{{.CreatedAt}}\t{{.UpdatedAt}}",
  "configFormat": "table {{.ID}}\t{{.Name}}\t{{.CreatedAt}}\t{{.UpdatedAt}}",
  "serviceInspectFormat": "pretty",
  "nodesFormat": "table {{.ID}}\t{{.Hostname}}\t{{.Availability}}",
  "detachKeys": "ctrl-e,e",
  "credsStore": "secretservice",
  "credHelpers": {
    "awesomereg.example.org": "hip-star",
    "unicorn.example.com": "vcbait"
  },
  "stackOrchestrator": "kubernetes",
  "plugins": {
    "plugin1": {
      "option": "value"
    },
    "plugin2": {
      "anotheroption": "anothervalue",
      "athirdoption": "athirdvalue"
    }
  },
  "proxies": {
    "default": {
      "httpProxy":  "http://user:pass@example.com:3128",
      "httpsProxy": "http://user:pass@example.com:3128",
      "noProxy":    "http://user:pass@example.com:3128",
      "ftpProxy":   "http://user:pass@example.com:3128"
    },
    "https://manager1.mycorp.example.com:2377": {
      "httpProxy":  "http://user:pass@example.com:3128",
      "httpsProxy": "http://user:pass@example.com:3128"
    },
  }
}
```

### Using experimental CLI features 

I will show you other methods in doing this, but if you're going to do it through docker's `config.json`, look for the following:

```json
{
  "experimental": "enabled",
  "debug": true
}
```
This for example will make `manifestation` possible, when calling `docker manifest`. 

## Working with insecure registries

The `manifest` command interacts solely with a Docker registry, and _solely_ a Docker registry. Thus, it has no way to query the engine for the list of allowed `insecure` registries. To allow the CLI to interact with an `insecure` registry, some `docker manifest` commands have an --insecure flag, and you'll see that we used the `--insecure` flag in our `.travis.yml` file for this long 'how-to'. For each transaction (e.g. create, which queries a registry, the `--insecure` flag must be specified.) If it's not, the latter will take precedent, and your build will error.

This flag tells the CLI that this registry call may ignore security concerns like missing or self-signed certificates using a command like:

```bash
ln -s /etc/ssl/certs/ca-certificates.crt /etc/docker/certs.d/mydomain.com:5000/ca-certificates.crt
```

Likewise, on a `docker manifest push` to an `--insecure` registry, the `--insecure` flag must be specified. If not, read what will happen above (the docker protocol heirarchy does its job). If this is not used with an `insecure` registry, the manifest command fails to find a registry that meets the default requirements, in turn will cause your Travis build to fail. 

## Using Travis to display the Manifests 

```yaml
---
language: shell
sudo: required
dist: xenial
os: linux

services:
  - docker

addons:
  apt:
    packages:
      - docker-ce

env:
  - DEPLOY=false repo=lucashalbert/curl docker_archs="amd64 ppc64le s390x"

install:
  - docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

before_script:
  - export ver=$(curl -s "https://pkgs.alpinelinux.org/package/edge/main/x86_64/curl" | grep -A3 Version | grep href | sed 's/<[^>]*>//g' | tr -d " ")
  - export build_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  - export vcs_ref=$(git rev-parse --short HEAD)

  # Montana's crucial workaround
  
script:
  - chmod u+x ./travis.sh
  - export DOCKER_CLI_EXPERIMENTAL=enabled

after_success:
  - docker images
  - docker manifest inspect --verbose lucashalbert/curl

branches:
  only:
    - master
  except:
    - /^*-v[0-9]/
    - /^v\d.*$/
    
    # .travis.yml created by Montana Mendy for Travis CI & IBM
```

## Setting up `env vars`

You can use your GitHub auth token, or just username/password, once logged in set the `env vars`: 

```bash
travis env set DOCKER_USERNAME username
travis env set DOCKER_PASSWORD pwd
```
You should see this in your build at some point, this is reassurance your `env vars` got saved.

![envvars](dockervars.png)

You'll also want to make sure you're logged into Docker, you can do this via: 

```bash
docker login 
``` 
![login](login.png)

That will now set both your Docker username/password as `env vars`. 

## Manifest

Once you've added `manifest`, it's crucial to add to your `.travis.yml`: 

```yaml
script: export DOCKER_CLI_EXPERIMENTAL=enabled
```
Alternatively you can run this in your project directory tree via: 

```bash
export DOCKER_CLI_EXPERIMENTAL=enabled
```

The two lines critical in the `.travis.yml` for the manifests to `print` are the following:

```yaml
after_success:
  - docker images
  - docker manifest inspect --verbose lucashalbert/curl
  - docker manifest inspect --insecure lucashalbert/curl
```
You want to use the `--verbose` and `--insecure` flags, to get as much `manifest` information as possible. This is true with any build. 

In theory, this doesn't have to be `after_success:` but we want to make the most sense of the `.travis.yml` logs.  Let's see if in particular for example, we can't find the `s390x` manifest: 

![s390x](s390x.png)

On the flip side, we can easily scroll through the `travis logs` and lookout for the `manifest` of `ppc64le`: 

![ppc64le](ppc64le.png) 

## Manifest JSON (amd64, arm, s390x, ppc64le)

```json
"schemaVersion": 2,
   "mediaType": "application/vnd.docker.distribution.manifest.list.v2+json",
   "manifests": [
      {
         "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
         "size": 945,
         "digest": "sha256:2ab48cb5665bebc392e27628bb49397853ecb1472ecd5ee8151d5ff7ab86e68d",
         "platform": {
            "architecture": "amd64",
            "os": "linux"
         }
      },
      {
         "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
         "size": 1363,
         "digest": "sha256:956f5cf1146bb6bb33d047e1111c8e887d707dde373c9a650b308a8ea7b40fa7",
         "platform": {
            "architecture": "arm",
            "os": "linux",
            "variant": "v6"
         }
      },
      {
         "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
         "size": 1363,
         "digest": "sha256:c6cc369f9824b7f6a19cca9d7f1789836528dd7096cdb4d1fc0922fd43af9d79",
         "platform": {
            "architecture": "arm",
            "os": "linux",
            "variant": "v7"
         }
      },
      {
         "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
         "size": 1363,
         "digest": "sha256:b9ae5a5f88f9e4f35c5ad8f83fbb0705cf4a38208a4e40c932d7abd2e7b7c40b",
         "platform": {
            "architecture": "arm64",
            "os": "linux",
            "variant": "v8"
         }
      },
      {
         "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
         "size": 1363,
         "digest": "sha256:4eca7b4f398526c8bf84be21f6c2c218119ed90a0ffa980dd4ba31ab50ca8cc5",
         "platform": {
            "architecture": "386",
            "os": "linux"
         }
      },
      {
         "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
         "size": 1363,
         "digest": "sha256:2239e5d3ee0e032514fe9c227c90cc5a1980a4c12602f683f4d0a647fb092797",
         "platform": {
            "architecture": "ppc64le",
            "os": "linux"
         }
      },
      {
         "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
         "size": 1363,
         "digest": "sha256:57523d3964bc9ee43ea5f644ad821838abd4ad1617eed34152ee361d538bfa3a",
         "platform": {
            "architecture": "s390x",
            "os": "linux"
         }
      }
   ]
}
Done. Your build exited with 0.
```

## Docker Manifest 

The `docker manifest` command by itself performs no action, in theory it's `null`. In order to operate on a manifest or manifest list, one of the subcommands must be used.

A single manifest is information about an image, such as `layers`, `size`, and `digest`. The docker manifest command also gives users additional information such as the `OS` and `arch` an image was built for:

![Manifest](manifest.png)

For more cursory info on [docker manifest](https://docs.docker.com/engine/reference/commandline/manifest/).

## Docker manifest inspect (verbose)

When setting `docker manifest inspect` with a `verbose` flag, it's going to be showing you a bit more information. So I've displayed this in the following screenshot with the `manifests` highlighted. 

![Verbose](manifest_build.png)

Alternatively you can `grep` the `manifests`. As you can see though, they are in the logs, with a passing build.

### Bash script using more of the manifest ecosystem

The below commands will come in more handy when you're writing a `bash` script. The following is a bash script I edited, so you can make sense of the ecosystem of other `docker manifest` commands:

```bash
#!/bin/bash

set -o errexit

main() {
  # arg 1 holds switch string
  # arg 2 holds node version
  # arg 3 holds tag suffix

  case $1 in
  "prepare")
    docker_prepare
    ;;
  "build")
    docker_build
    ;;
  "test")
    docker_test
    ;;
  "tag")
    docker_tag
    ;;
  "push")
    docker_push
    ;;
  "manifest-list-version")
    docker_manifest_list_version "$2" "$3"
    ;;
  "manifest-list-test-beta-latest")
    docker_manifest_list_test_beta_latest "$2" "$3"
    ;;
  *)
    echo "none of above!"
    ;;
  esac
}

function docker_prepare() {
  # Prepare the machine before any code installation scripts
  setup_dependencies

  # Update docker configuration to enable docker manifest command
  update_docker_configuration

  # Prepare qemu to build images other then x86_64 on travis
  prepare_qemu
}

function docker_build() {
  # Build Docker image
  echo "DOCKER BUILD: Build Docker image."
  echo "DOCKER BUILD: arch - ${ARCH}."
  echo "DOCKER BUILD: build version -> ${BUILD_VERSION}."
  echo "DOCKER BUILD: webtrees version -> ${WT_VERSION}."
  echo "DOCKER BUILD: qemu arch - ${QEMU_ARCH}."
  echo "DOCKER BUILD: docker file - ${DOCKER_FILE}."

  docker build --no-cache \
    --build-arg ARCH=${ARCH} \
    --build-arg BUILD_DATE=$(date +"%Y-%m-%dT%H:%M:%SZ") \
    --build-arg BUILD_VERSION=${BUILD_VERSION} \
    --build-arg BUILD_REF=${TRAVIS_COMMIT} \
    --build-arg WT_VERSION=${WT_VERSION} \
    --build-arg QEMU_ARCH=${QEMU_ARCH} \
    --file ./${DOCKER_FILE} \
    --tag ${TARGET}:build .
}

function docker_test() {
  echo "DOCKER TEST: Test Docker image."
  echo "DOCKER TEST: testing image -> ${TARGET}:build"

  docker run -d --rm --name=testing ${TARGET}:build
  if [ $? -ne 0 ]; then
    echo "DOCKER TEST: FAILED - Docker container testing failed to start."
    exit 1
  else
    echo "DOCKER TEST: PASSED - Docker container testing succeeded to start."
  fi
}

function docker_tag() {
  echo "DOCKER TAG: Tag Docker image."

  echo "DOCKER TAG: tagging image - ${TARGET}:${BUILD_VERSION}-${ARCH}"
  docker tag ${TARGET}:build ${TARGET}:${BUILD_VERSION}-${ARCH}
}

function docker_push() {
  echo "DOCKER PUSH: Push Docker image."

  echo "DOCKER TAG: pushing image - ${TARGET}:${BUILD_VERSION}-${ARCH}"
  docker push ${TARGET}:${BUILD_VERSION}-${ARCH}
}

function docker_manifest_list_version() {

  echo "DOCKER MANIFEST: Create and Push docker manifest list - ${TARGET}:${BUILD_VERSION}."

  docker manifest create ${TARGET}:${BUILD_VERSION} \
    ${TARGET}:${BUILD_VERSION}-amd64 \
    ${TARGET}:${BUILD_VERSION}-arm32v7 \
    ${TARGET}:${BUILD_VERSION}-arm64v8 \
    ${TARGET}:${BUILD_VERSION}-ppc64le \
    ${TARGET}:${BUILD_VERSION}-s390x

  docker manifest annotate ${TARGET}:${BUILD_VERSION} ${TARGET}:${BUILD_VERSION}-arm32v7 --os=linux --arch=arm --variant=v7
  docker manifest annotate ${TARGET}:${BUILD_VERSION} ${TARGET}:${BUILD_VERSION}-arm64v8 --os=linux --arch=arm64 --variant=v8
  docker manifest annotate ${TARGET}:${BUILD_VERSION} ${TARGET}:${BUILD_VERSION}-ppc64le --os=linux --arch=ppc64le
  docker manifest annotate ${TARGET}:${BUILD_VERSION} ${TARGET}:${BUILD_VERSION}-s390x --os=linux --arch=s390x
  
  docker manifest push ${TARGET}:${BUILD_VERSION}
  
  docker run --rm mplatform/mquery ${TARGET}:${BUILD_VERSION}
}

function docker_manifest_list_test_beta_latest() {

  if [[ ${BUILD_VERSION} == *"test"* ]]; then
    export TAG_PREFIX="test";
  elif [[ ${BUILD_VERSION} == *"beta"* ]]; then
    export TAG_PREFIX="beta";
  else
    export TAG_PREFIX="latest";
  fi

  echo "DOCKER MANIFEST: Create and Push docker manifest list - ${TARGET}:${TAG_PREFIX}."

  docker manifest create ${TARGET}:${TAG_PREFIX} \
    ${TARGET}:${BUILD_VERSION}-amd64 \
    ${TARGET}:${BUILD_VERSION}-arm32v7 \
    ${TARGET}:${BUILD_VERSION}-arm64v8 \
    ${TARGET}:${BUILD_VERSION}-ppc64le \
    ${TARGET}:${BUILD_VERSION}-s390x

  docker manifest annotate ${TARGET}:${TAG_PREFIX} ${TARGET}:${BUILD_VERSION}-arm32v7 --os=linux --arch=arm --variant=v7
  docker manifest annotate ${TARGET}:${TAG_PREFIX} ${TARGET}:${BUILD_VERSION}-arm64v8 --os=linux --arch=arm64 --variant=v8
  docker manifest annotate ${TARGET}:${TAG_PREFIX} ${TARGET}:${BUILD_VERSION}-ppc64le --os=linux --arch=ppc64le
  docker manifest annotate ${TARGET}:${TAG_PREFIX} ${TARGET}:${BUILD_VERSION}-s390x --os=linux --arch=s390x

  docker manifest push ${TARGET}:${TAG_PREFIX}
  
  docker run --rm mplatform/mquery ${TARGET}:${TAG_PREFIX}
}

function setup_dependencies() {
  echo "PREPARE: Setting up dependencies."
  sudo apt update -y
  sudo apt install --only-upgrade docker-ce -y
}

function update_docker_configuration() {
  echo "PREPARE: Updating docker configuration"

  mkdir $HOME/.docker

  # enable experimental to use docker manifest command
  echo '{
    "experimental": "enabled"
  }' | tee $HOME/.docker/config.json

  # enable experimental
  echo '{
    "experimental": true,
    "storage-driver": "overlay2",
    "max-concurrent-downloads": 50,
    "max-concurrent-uploads": 50
  }' | sudo tee /etc/docker/daemon.json

  sudo service docker restart
}

function prepare_qemu() {
  echo "PREPARE: Qemu"
  # Prepare qemu to build non amd64 / x86_64 images
  docker run --rm --privileged multiarch/qemu-user-static:register --reset
  mkdir tmp
  pushd tmp &&
    curl -L -o qemu-x86_64-static.tar.gz https://github.com/multiarch/qemu-user-static/releases/download/$QEMU_VERSION/qemu-x86_64-static.tar.gz && tar xzf qemu-x86_64-static.tar.gz &&
    curl -L -o qemu-arm-static.tar.gz https://github.com/multiarch/qemu-user-static/releases/download/$QEMU_VERSION/qemu-arm-static.tar.gz && tar xzf qemu-arm-static.tar.gz &&
    curl -L -o qemu-ppc64le-static.tar.gz https://github.com/multiarch/qemu-user-static/releases/download/$QEMU_VERSION/qemu-ppc64le-static.tar.gz && tar xzf qemu-ppc64le-static.tar.gz &&
    curl -L -o qemu-s390x-static.tar.gz https://github.com/multiarch/qemu-user-static/releases/download/$QEMU_VERSION/qemu-s390x-static.tar.gz && tar xzf qemu-s390x-static.tar.gz &&
    curl -L -o qemu-aarch64-static.tar.gz https://github.com/multiarch/qemu-user-static/releases/download/$QEMU_VERSION/qemu-aarch64-static.tar.gz && tar xzf qemu-aarch64-static.tar.gz &&
    popd
}

main "$1" "$2" "$3"
```

### Other commands

| Command                  | Description                                                           |
|--------------------------|-----------------------------------------------------------------------|
| docker manifest annotate | Add additional information to a local image manifest                  |
| docker manifest create   | Create a local manifest list for annotating and pushing to a registry |
| docker manifest inspect  | Display an image manifest, or manifest list                           |
| docker manifest push     | Push a manifest list to a repository                                  |


Reminder the commands on the left are all `parent commands` and have `flags` that can be attached to them for different behaviors/functions.

## Annotations 

Annotations are allowed in docker for the reason of defining architecture and operating system (overriding the image’s current values), os features, and an architecture variant, this takes precedent over `env vars` in the docker protocol heirarchy. An example of using `annotation` would look something like:

```bash
docker manifest annotate 00.00.00.000:5000/cool-IBM-test:v1 00.00.00.00:5000/cool-IBM-test --arch ppc64le, s390x
```

In this example, the only `archs` that are going to be building is: 

```bash
ppc64le
s390x
```

## Inspect a manifest list (`cool-IBM-test`) 

```json
 docker manifest inspect cool-IBM-test:v1
{
         "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
         "size": 425,
         "digest": "sha256:df436846483aff62bad830b730a0d3b77731bcf98ba5e470a8bbb8e9e346e4e8",
         "platform": {
            "architecture": "ppc64le",
            "os": "linux"
         }
      },
      {
         "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
         "size": 425,
         "digest": "sha256:5bb8e50aa2edd408bdf3ddf61efb7338ff34a07b762992c9432f1c02fc0e5e62",
         "platform": {
            "architecture": "s390x",
            "os": "linux"
         }
      }
   ]
}
```

Phew, that was a lot! This should now give you the opportunity to mix and match `docker manifest` with Travis. I haven't seen much on this on GitHub or really anywhere. So it's really my pleasure to share my custom `.travis.yml` file, and show you what works, and I left all my history open -- so you can see where things didn't go so smoothly! I hope you enjoyed the read.

### Authors 
Montana Mendy - [Montana](https://github.com/Montana) (Rails Engineer/DevRel @ Travis CI) 
