# Manifest with Travis CI 

First thing, you'll need to set your `docker env vars`, you can do this by once the repo is created, along with your `.travis.yml` and your `Dockerfile` you can login into Travis from the CLI via:

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

## The .travis.yml file for Docker Manifests 

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

## Manifest JSON (amd64, arm, s390x, ppc64le). 

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

### Authors 
Montana Mendy - [Montana](https://github.com/Montana)
