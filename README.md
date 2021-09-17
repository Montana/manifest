![Header](header.png)

[![Build Status](https://travis-ci.com/Montana/manifest.svg?branch=master)](https://travis-ci.com/Montana/manifest)

# Docker Manifest with Travis CI 

_BEFORE_ you start reading, this guide is only for Travis CI and no other CI provider, also there might be some things you may want to check out first:

---

**NB**: All these scripts, mini programs, and obviously the `.travis.yml` file I've authored pass the Travis build individually, so if they break please revert your branch in GitHub by using `git revert HEAD`. You could also use `git reflog` as well, you _might also_ want to check `git log`, and see `travis whatsup`. 

---


| Language | Filetype                                       | Travis Pass/Fail |
| ------- | ---------------------------------------------- | ---------------- |
| Bash    | [travis.sh](travis.sh)                         | Pass             |
| YAML    | [.travis.yml](.travis.yml)                     | Pass             |
| Bash    | [annotations.sh](annotations.sh)               | Pass             |
| Python3 | [charcount.py](charcount.py)                   | Pass             |
| Bash    | [crontest.sh](crontest.sh)                     | Pass             |
| Bash    | [cron_table.sh](cron_table.sh)                 | Pass             |
| Bash    | [ci.sh](ci.sh)                                 | Pass             |
| Bash    | [caching.sh](caching.sh)                       | Pass             |
| Bash    | [build.sh](build.sh)                           | Pass

* My custom `travis.sh` bash script to set this env up: [travis.sh](travis.sh) 
* My custom `.travis.yml` for this use case: [.travis.yml](.travis.yml)
* Heavily edited bash script I customized for this use case entiteld `annotations.sh`: [annotations.sh](annotations.sh)
* The mini Python app I created to test within Travis in conjunction with `manifest` entitled `charcount.py`: [charcount.py](charcount.py)
* My script that tests `crons`. The file as you can tell from the extension is in bash:  [crontest.sh](crontest.sh)
* My cron table I made - if you choose to do randomized `cron` checks, or on different days of the week: [cron_table.sh](cron_table.sh)
* My quick print in bash of `"Hello Travis"`. The file is called `ci.sh`, it's in bash -- if you just need a quick printout: [ci.sh](ci.sh)
* My bash script on Docker `manifest` caching: [caching.sh](caching.sh)

> This is so you can get a better idea how this works after you setup your `env vars`, and ultimately inject your own 'components' like 'charcount' to have flexibility with the test use case I've setup here. The only script that will be being used (mandatory) is the `travis.sh` under the `script:` hook in the `.travis.yml` file. Everything else is optional. 

You'll want to see this before you can move on which is [travis.sh](travis.sh) getting executed and passing the build:

![Success](success.png)

> My script [travis.sh](travis.sh) passing in the Travis CI build, which means we are off to start seeing `manifests`.

## Branches coming soon

The current stucture (in theory) will look a bit like this:

```
dat-manifest/master
│   README.md
│       
│
└───dat-manifest/main
│   │   README.md
│   │   Dockerfile.cross (PR)
│   │
│   └───dat-manifest/branch3
│       │   README.md
│       │   .travis.yml (PR)
│       │   ...
│   
└───dat-manifest/scripts
    │   cron_table.sh
    │   travis.sh (PR)
```

## Getting started

![Gif](https://github.com/Montana/manifest-unicorn/raw/master/manifest.gif)
> The first thing to do before looking at `manifests` is loginng into Docker through the Docker CLI.

First thing, you'll need to set your `docker env vars`, you can do this once the repo is created, along with your `.travis.yml` and your `Dockerfile` you can login into Travis from the CLI via:

```bash
travis login --pro --github-token (your github token) 
```

Then just to make sure you're logged into the proper Travis account run: 

```bash
travis whatsup
```

It's my own personal opinion, when pushing for `manifests` you should always commit with `-asm` so you're signing off on it so, instead of the regular `git commit -m "whatever"` you'd run `git commit -asm "whatever"`. In this particular example, I grabbed from the `DockerHub` the following packages: 

```bash
lucashalbert/curl
ppc64le/node
s390x/python  
ibmjava:jre 
```

These are the perfect packages (`cURL`), (`ppc64le`), (`s390x`), (`ibmjava:jre`), to show a multiarch docker image using `ppc64le`, `s390x`, and it's manifests.


## Docker Manifest Layers

Docker images have a bunch of layers. For each command in the `Dockerfile`, Docker generates a layer with all new files, for example `CMD`. So, each layer is a set of differences from the previous one, for example below is a `digest` of an React app I'm currently working on:

![ReactLayers](layers.png)

> Showing the typical Docker `digest` and `sha256` affiliated with the React app in question.

## Docker Manifest Caching 

Docker `manifest` caching is possible, you need to fetch the unique values - but the short end of this is the following:

```bash
#!/bin/bash
docker history -q IMAGE_HERE | grep -v missing && tar -xOf file.tar manifest.json | tr , '\n' | grep -o '"Config":".*"' | awk -F ':' '{print $2}' | awk '{print substr($0,2,12)}'

# Alternatively use, tar -xOf file.tar manifest.json | tr , '\n' | grep -o '"Config":".*"' | awk -F ':' '{print $2}' | awk '{print substr($0,2,12)}'
```
This outputs everything, and would suggest if you're into caching. 

## Breaking the `digest`

When `ls` the folder, this is how the folder is structured, or should be:

```
├── 1/
├── 2/
├── 3/
├── 4/
├── config.json
└── manifest.json
```

We want to re-tar and reload `docker load`:

```bash
tar -cf new-a.tar -C a/ .
docker load -i new-a.tar
Loaded image ID: sha256:24b...975
```

The digest equals the `sha256` of the `config.json` file, it runs! 

## Check if image:tag combination already exists on DockerHub:

Follow this bash script I edited that will have the image combination search function, either `result` or `null`:

```bash
#!/bin/bash

func docker_image_tag_exists() {
    EXISTS=$(curl -s https://hub.docker.com/v2/repositories/$1/tags/?page_size=10000 | jq -r "[.results? | .[]? | .name == \"$2\"] | any")
    test ${EXISTS} = true
}

if docker_image_tag_exists $1 $2; then
    echo "true" # enforce image tag to exist 
else
    echo "false" # enforce null fetch if image tag doesn't exist
fi
```
This will be a quicky way to check if a particularly Docker `image:tag` combination exists on DockerHub, so you can quickly make decisions and possibly `grep` image name combos, and get `manifests` quicker on certain items. 


### What are Docker Manifests, why do I need to use manifest? 

Any registry or runtime that claims to have a certain Docker distribution image specification (this can easily be checked) support will be interacting with the various `manifest` types to find out the following things inside a image:

1. What are the _actual_ filesystem content, (layers) will be needed to build the root filesystem for the container.

2. Any specific image config that is necessary to know how to run a container, some are more niche than others for using certain images. For example, information like what command(s) to run when starting the container (as probably represented in the Dockerfile that was used to build the image).

In short, The Docker container `manifest` is a file that contains data about a container image. Specifically `digest`, `sha256`, and most importantly `arch`. We can create a `docker manifest` which points to images for different architectures so that when using the image on a particular architecture Docker automatically pulls the desired image. 

The main reason for `manifest` is to cross-build docker images.


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

## Fat Manifest

The `manifest list` is the “fat manifest” which points to specific image manifests for one or various platforms or architectures. Its use is optional, and relatively few images will use one of these manifests. You can distinguish via the content-Type returned in a `HTTP` response usually.

## Image Digest 

When inspecting a `digest` in a directory tree, it should look similar to this:

![tree](tree.png)

> Docker's JSON config file describes the environment that built the docker image and its history through `manifest` and a good example is above, and the hash beginning with **5d1**.
(here, `5d1cdcfd1c744987e4916f7815874391b29bff62e3df2d29885683e1b39e4c0a.json`).

### Why I use cron jobs 

For a build like this, the `cron` and at a services level, it can enable programmers to schedule tasks to run at a specific time in the future. You can think of it as setting a coffee maker. The at service specifies a one-time task that runs at a certain time. The `cron` service can schedule tasks on a repetitive basis and in rapid succession, such as daily, weekly, or monthly tasks that involve almost anything.

You'll see some of these `dcrons` around, you'll start why I _personally_ use them. They are _NOT_ for everybody. I made a table of the most common scheduler type crons. You can get a better idea on how to write them and implement them by looking at my [cron_table.sh](cron_table.sh): 

| Version          | Edit crontab | Remove crontab       | New crontab   | List cron-jobs |
|------------------|--------------|----------------------|---------------|----------------|
| dcron            | crontab -e   | crontab -d [user]    | crontab file  | crontab -l     |
| fcron            | fcrontab -e  | fcrontab -r [user]   | fcrontab file | fcrontab -l    |
| cronie and bcron | crontab -e   | crontab -r -u [user] | crontab file  | crontab -l     |


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

## Using manifest wthout installation

If you want to use `manifest` for simple query operations? For example, maybe you only want to query if a specific image:tag combination is a manifest list entry or not, something I call a 'if or that' query. If so, what platforms are listed in the manifest itself.

You can consume this feature of `manifest` without installing the binary as long as you are querying public (e.g. not private/authentication-requiring DockerHub registries, and secure ones not insecure ones). This can be done in a different way by another tool called `mquery`. Using `mquery` you can query the Docker image itself using these commands: 

You can use mquery via a multi-platform image currently located on DockerHub as mplatform/mquery:latest. For example, you can query the mquery image itself with the following command:

```bash
docker run --rm mplatform/mquery mplatform/mquery
Image: mplatform/mquery
 * Manifest List: Yes
 * Supported platforms:
   - linux/ppc64le
   - linux/s390x
   ```

For reference, the  `mquery` program in itself is a small Golang program that queries any functions and calls `manifest` while running via [OpenWhisk](https://openwhisk.apache.org/) from Apache in [IBM Cloud Functions](https://cloud.ibm.com/docs/openwhisk/index.html#getting-started-with-cloud-functions). 

## Working with insecure registries

The `manifest` command interacts solely with a Docker registry, and _solely_ a Docker registry. Thus, it has no way to query the engine for the list of allowed `insecure` registries. To allow the CLI to interact with an `insecure` registry, some `docker manifest` commands have an --insecure flag, and you'll see that we used the `--insecure` flag in our `.travis.yml` file for this long 'how-to'. For each transaction (e.g. create, which queries a registry, the `--insecure` flag must be specified.) If it's not, the latter will take precedent, and your build will error within Travis.

This flag tells the CLI that this registry call may ignore security concerns like missing or self-signed certificates using a command like:

```bash
ln -s /etc/ssl/certs/ca-certificates.crt /etc/docker/certs.d/mydomain.com:5000/ca-certificates.crt
```

> The `--insecure` flag is not required to annotate a `manifest` list on some occassions -- specifically when specified somewhere else (`.travis.yml`, `Dockerfile`), since annotations are to a locally-stored copy in general, and of course this is of a `manifest` list. You may also skip the `--insecure` flag if you are performing a `docker manifest` inspect on a locally-stored `manifest list`. Be sure to keep in mind that locally-stored `manifest lists` are never used by the engine on a docker pull. So if you run `docker pull` that `manifest` will not be used. 


Likewise, on a `docker manifest push` to an `--insecure` registry, the `--insecure` flag must be specified. If not, read what will happen above (the docker protocol heirarchy does its job). If this is not used with an `insecure` registry, the manifest command fails to find a registry that meets the default requirements, in turn will cause your Travis build to fail. 

## Manifest parent commands 

In this case the `parent command` is the command that `inits` what you want to do with `docker manifest`. It gets a little more complex when `Dockerfile`. For example, the image’s parent image (in a `Dockerfile`) is the image designated in the `FROM` directive in the image’s Dockerfile. All subsequent commands are based on this parent image. A `Dockerfile` with the `FROM scratch` directive uses no parent image, as it creates mostly a base docker image, and example of this would be:

```Dockerfile
FROM scratch
WORKDIR /root/
# Copy the file from the build image
COPY --from=build /go/src/app .
CMD ["./app"]
```
A table made, to graphically show you the definition of `parent command` for all you visual learners out there, I know I am:

| Command | Description                          |
|---------|--------------------------------------|
| docker  | The base command for the Docker CLI. |

The `docker` command, will directly lead us into the next section on the proper usage of `docker manifest`. 

## Child commands in Docker as it pertains to `manifest` 

Sometimes it's good to regroup, and put all command in one compact table, we can get lost when we are running `docker manifest` in variant. These tables will be great to go back and look at if you have questions about what a command does later. I've made one for the `child` commands for docker `manifest`:

| Child commands           | Description                                                           |
|--------------------------|-----------------------------------------------------------------------|
| docker manifest annotate | Add additional information to a local image manifest                  |
| docker manifest create   | Create a local manifest list for annotating and pushing to a registry |
| docker manifest inspect  | Display an image manifest, or manifest list                           |
| docker manifest push     | Push a manifest list to a repository                                  |

## Test a docker registry for "manifest list" support

This script expects and _requires_ `env vars`. Please run the following: 

```bash
./test-registry.sh r.myprivreg.com/somerepo
```
This will give you the binary answer of yes/no if there is `manifest` support for that DockerHub repo.


![Container Manifest](container-manifest.png) 
> Flow chart explaining how my `.travis.yml` works.

## Using Travis to display the Manifests 

The following is the [.travis.yml](.travis.yml) file in the repo which also uses [travis.sh](travis.sh) bash script I wrote to complete some of the `env var` tasks, while pushing to the custom `.travis.yml` file I made for this use case.

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
  - DEPLOY=false repo=ibmjava:jre docker_archs="amd64 ppc64le s390x"

install:
  - docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

before_script:
  - export ver=$(curl -s "https://pkgs.alpinelinux.org/package/edge/main/x86_64/curl" | grep -A3 Version | grep href | sed 's/<[^>]*>//g' | tr -d " ")
  - export build_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  - export vcs_ref=$(git rev-parse --short HEAD)

  # Montana's crucial workaround
  
script:
  - chmod u+x ./travis.sh
  - chmod u+x /build.sh
  - export DOCKER_CLI_EXPERIMENTAL=enabled # crucial to use manifest

after_success:
  - docker images
  - docker manifest inspect --verbose lucashalbert/curl # multiarch build
  - docker manifest inspect --insecure lucashalbert/curl # multiarch build 
  - docker manifest inspect --verbose ppc64le/node # IBM power build 
  - docker manifest inspect --insecure ppc64le/node # IBM power build 
  - docker manifest inspect --verbose s390x/python # IBM Z build 
  - docker manifest inspect --insecure s390x/python # IBM z build
  - docker manifest inspect --verbose ibmjava:jre # official Docker IBM Java (Multiarch) build
  - docker manifest inspect --insecure ibmjava:jre # official Docker IBM Java (Multiarch) build

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

> Travis CI confirming that our `env vars` are safe and secure while it builds. 

For some setting the `env vars` in the CLI is the best option, but for others using the Travis CI user interface is easier, and quicker. Click Settings -> Environment Variables then add your `DOCKER` env vars. 

![UI](envvarui.png)

> We are using the UI to enter the Travis CI `env vars` (rather than the CLI). 

For both cases, you'll also want to make sure you're logged into Docker, you can do this via: 

```bash
docker login 
``` 
![login](login.png)

> Login succeeded! This is crucial to have everything working properly, specifically getting the `docker manifests`. 

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

The lines critical in the `.travis.yml` for the manifests to `print` are the following:

```yaml
after_success:
  - docker images
  - docker manifest inspect --verbose lucashalbert/curl
  - docker manifest inspect --insecure lucashalbert/curl
  - docker manifest inspect --verbose ppc64le/node
  - docker manifest inspect --insecure ppc64le/node
  - docker manifest inspect --verbose s390x/
  - docker manifest inspect --insecure s390x/python
  - docker manifest inspect --verbose ibmjava:jre 
  - docker manifest inspect --insecure ibmjava:jre 
  ```
You want to use the `--verbose` and `--insecure` flags, to get as much `manifest` information as possible. This is true with any build. 

In theory, this doesn't have to be `after_success:` but we want to make the most sense of the `.travis.yml` logs.  Let's see if in particular for example, we can't find the `s390x` manifest: 

![s390x](s390x.png)

> We are looking at the `s390x manifest`.

On the flip side, we can easily scroll through the `travis logs` and lookout for the `manifest` of `ppc64le`: 

![ppc64le](ppc64le.png) 

> When the exact same `Dockerfile` is built again, a new `digest` in the `manifest` is created for that build, irrespective of the fact, that the same file is being built again and in the same environment. The only difference that makes these two different digests is the `container.key` and the `creation-timestamp`.

## Create and push a `manifest list`

In order to spawn a `manifest list`, you first create the manifest list locally (localhost) by specifying the constituent images, (you can check them using `docker -ps -a`) if you would like to have included in your `manifest list`. Keep in mind that this is pushed to a docker registry, so if you want to push to a registry other than the docker registry, you need to create your manifest list with the registry name or IP and port. This is similar to tagging an image and pushing it to a foreign registry.

After you have created your local copy of the `manifest list`, you may optionally annotate it. Annotations allowed are the architecture and operating system (e.g. `ppc64le`, `linux`) (overriding the image’s current values, and again this is from the heirarchy of docker protocols), `os features`, and an the `architecture variant` you're wanting to use:

```bash
docker manifest create 0.0.0.0:5000/cool-ibm-test:v1 \
```
Then you should see: 

```bash
  00.00.00.00:5000/cool-ibm-test-ppc64le-linux:v1 \
  0.00.00.00:5000/cool-ibm-test-s390x-linux:v1 \
  0.00.00.00:5000/cool-ibm-test-amd64-linux:v1 \
  ```
Lastly, you need to `push` your `docker manifest` list to the desired registry. Below are descriptions of these three commands, and an example putting them all together:

```bash
docker manifest annotate 00.00.00.00:5000/cool-ibm-test-linux:v1 \ 00.00.00.00:5000/cool-ibm-test-linux:v1 \ --arch ppc64le
```
 
That's really it for `pushing` a `manifest`. There's also arbitrary flags, and the docker heirarch protocol, which are well explained in this document.

![Manifest Ubuntu](ppc64leubuntu.png)

> Each layer of the `manifest` is comprised of a JSON file (which looks like the `.config` file we talked about earlier), a `VERSION` file with the string 1.0, and a `layer.tar` file containing the images files. In this particular case above, we are going to inspect `ppc64le/node` from DockerHub in my Ubuntu VM, using VMWare.

You might need to resolve some dependencies if doing `manifest` on Ubuntu, this is fairly easiy:

```bash
sudo apt install ruby-dev libffi-dev make gcc
sudo gem install travis
```
Then make sure Travis is installed:

```bash
which travis
``` 

Then you're good to go, now lets move on to pushing a manifest:

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

## The `build.sh` script 

```bash
#!/bin/bash -x

for docker_arch in ${docker_archs}; do
    case ${docker_arch} in
        ppc64le ) qemu_arch="ppc64le" image_arch="ppc64le" variant=""   ;;
        s390x   ) qemu_arch="s390x"   image_arch="s390x"   variant=""   ;;
    esac
    cp Dockerfile.cross Dockerfile.${docker_arch}
    sed -i "s|__BASEIMAGE_ARCH__|${docker_arch}|g" Dockerfile.${docker_arch}
    sed -i "s|__QEMU_ARCH__|${qemu_arch}|g" Dockerfile.${docker_arch}
    sed -i "s|__CURL_VER__|${ver}|g" Dockerfile.${docker_arch}
    sed -i "s|__BUILD_DATE__|${build_date}|g" Dockerfile.${docker_arch}
    sed -i "s|__VCS_REF__|${vcs_ref}|g" Dockerfile.${docker_arch}
    if [ ${docker_arch} == 'amd64' ]; then
        sed -i "/__CROSS__/d" Dockerfile.${docker_arch}
        cp Dockerfile.${docker_arch} Dockerfile
    else
        sed -i "s/__CROSS__//g" Dockerfile.${docker_arch}
    fi


    # Check for qemu static bins
    if [[ ! -f qemu-${qemu_arch}-static ]]; then
        echo "Downloading the qemu static binaries for ${docker_arch}"
        wget -q -N https://github.com/multiarch/qemu-user-static/releases/download/v4.0.0-4/x86_64_qemu-${qemu_arch}-static.tar.gz
        tar -xvf x86_64_qemu-${qemu_arch}-static.tar.gz
        rm x86_64_qemu-${qemu_arch}-static.tar.gz
    fi

    # Build image
    docker build -f Dockerfile.${docker_arch} -t ${repo}:${docker_arch}-${ver} .
   
    # Check if build should be deployed
    if [ "$TRAVIS_BRANCH" = "master" ] && [ "${TRAVIS_PULL_REQUEST}" = "false" ]; then 
        # Push image
        docker push ${repo}:${docker_arch}-${ver}

        # Create arch/ver docker manifest
        DOCKER_CLI_EXPERIMENTAL=enabled docker manifest create ${repo}:${docker_arch}-${ver} ${repo}:${docker_arch}-${ver}
        
        # Annotate arch/ver docker manifest
        if [ ! -z "${variant}" ]; then
            DOCKER_CLI_EXPERIMENTAL=enabled docker manifest annotate ${repo}:${docker_arch}-${ver} ${repo}:${docker_arch}-${ver} --os linux --arch ${image_arch} --variant ${variant}
        else
            DOCKER_CLI_EXPERIMENTAL=enabled docker manifest annotate ${repo}:${docker_arch}-${ver} ${repo}:${docker_arch}-${ver} --os linux --arch ${image_arch}
        fi

        # Generate Dynamic Manifest Image List
        if [ -z "${manifest_images}" ]; then
            manifest_images="${repo}:${docker_arch}-${ver}"
        else
            manifest_images="${manifest_images} ${repo}:${docker_arch}-${ver}"
        fi
    elif [ "$DEPLOY" = true ]; then
        # Tag image with travis branch
        docker tag ${repo}:${docker_arch}-${ver} ${repo}:${docker_arch}-${ver}-${TRAVIS_BRANCH}

        # Push tagged image
        docker push ${repo}:${docker_arch}-${ver}-${TRAVIS_BRANCH}

        # Create tagged arch/ver docker manifest
        DOCKER_CLI_EXPERIMENTAL=enabled docker manifest create ${repo}:${docker_arch}-${ver}-${TRAVIS_BRANCH} ${repo}:${docker_arch}-${ver}-${TRAVIS_BRANCH}
        
        # Annotate tagged arch/ver docker manifest
        if [ ! -z "${variant}" ]; then
            DOCKER_CLI_EXPERIMENTAL=enabled docker manifest annotate ${repo}:${docker_arch}-${ver}-${TRAVIS_BRANCH} ${repo}:${docker_arch}-${ver}-${TRAVIS_BRANCH} --os linux --arch ${image_arch} --variant ${variant}
        else
            DOCKER_CLI_EXPERIMENTAL=enabled docker manifest annotate ${repo}:${docker_arch}-${ver}-${TRAVIS_BRANCH} ${repo}:${docker_arch}-${ver}-${TRAVIS_BRANCH} --os linux --arch ${image_arch}
        fi

        # Generate Dynamic Manifest Image List
        if [ -z "${manifest_images}" ]; then
            manifest_images="${repo}:${docker_arch}-${ver}-${TRAVIS_BRANCH}"
        else
            manifest_images="${manifest_images} ${repo}:${docker_arch}-${ver}-${TRAVIS_BRANCH}"
        fi
    else
        echo "Skipping image deployment... Not configured to deploy images/manifests to DockerHub"
    fi
done

# Check if build should be deployed
if [ "$TRAVIS_BRANCH" = "master" ] && [ "${TRAVIS_PULL_REQUEST}" = "false" ]; then 
    # Create version specific docker manifest
    DOCKER_CLI_EXPERIMENTAL=enabled docker manifest create ${repo}:${ver} ${manifest_images}

    # Create latest version docker manifest
    DOCKER_CLI_EXPERIMENTAL=enabled docker manifest create ${repo}:latest ${manifest_images}

elif [ "$DEPLOY" = true ]; then
    # Create version specific docker manifest
    DOCKER_CLI_EXPERIMENTAL=enabled docker manifest create ${repo}:${ver}-${TRAVIS_BRANCH} ${manifest_images}

    # Create latest version docker manifest
    DOCKER_CLI_EXPERIMENTAL=enabled docker manifest create ${repo}:latest-${TRAVIS_BRANCH} ${manifest_images}

else
    echo "Skipping version specific and latest tag docker manifest creation... Not configured to deploy images/manifests to DockerHub"
fi

for docker_arch in ${docker_archs}; do
    case ${docker_arch} in
        ppc64le ) qemu_arch="ppc64le" image_arch="ppc64le" variant=""   ;;
        s390x   ) qemu_arch="s390x"   image_arch="s390x"   variant=""   ;;
    esac

    # Check if build should be deployed
    if [ "$TRAVIS_BRANCH" = "master" ] && [ "${TRAVIS_PULL_REQUEST}" = "false" ]; then 
        # Annotate arch/ver docker manifest
        if [ ! -z "${variant}" ]; then
            # Annotate version specific docker manifest
            DOCKER_CLI_EXPERIMENTAL=enabled docker manifest annotate ${repo}:${ver} ${repo}:${docker_arch}-${ver} --os linux --arch ${image_arch} --variant ${variant}

            # Annotate latest docker manifest
            DOCKER_CLI_EXPERIMENTAL=enabled docker manifest annotate ${repo}:latest ${repo}:${docker_arch}-${ver} --os linux --arch ${image_arch} --variant ${variant}

        else
            # Annotate version specific docker manifest
            DOCKER_CLI_EXPERIMENTAL=enabled docker manifest annotate ${repo}:${ver} ${repo}:${docker_arch}-${ver} --os linux --arch ${image_arch}

            # Annotate latest docker manifest
            DOCKER_CLI_EXPERIMENTAL=enabled docker manifest annotate ${repo}:latest ${repo}:${docker_arch}-${ver} --os linux --arch ${image_arch}
        fi

        # Push arch/ver docker manifest
        DOCKER_CLI_EXPERIMENTAL=enabled docker manifest push ${repo}:${docker_arch}-${ver}
    elif [ "$DEPLOY" = true ]; then
        # Annotate arch/ver docker manifest
        if [ ! -z "${variant}" ]; then
            # Annotate version specific docker manifest
            DOCKER_CLI_EXPERIMENTAL=enabled docker manifest annotate ${repo}:${ver}-${TRAVIS_BRANCH} ${repo}:${docker_arch}-${ver}-${TRAVIS_BRANCH} --os linux --arch ${image_arch} --variant ${variant}

            # Annotate latest docker manifest
            DOCKER_CLI_EXPERIMENTAL=enabled docker manifest annotate ${repo}:latest-${TRAVIS_BRANCH} ${repo}:${docker_arch}-${ver}-${TRAVIS_BRANCH} --os linux --arch ${image_arch} --variant ${variant}

        else
            # Annotate version specific docker manifest
            DOCKER_CLI_EXPERIMENTAL=enabled docker manifest annotate ${repo}:${ver}-${TRAVIS_BRANCH} ${repo}:${docker_arch}-${ver}-${TRAVIS_BRANCH} --os linux --arch ${image_arch}

            # Annotate latest docker manifest
            DOCKER_CLI_EXPERIMENTAL=enabled docker manifest annotate ${repo}:latest-${TRAVIS_BRANCH} ${repo}:${docker_arch}-${ver}-${TRAVIS_BRANCH} --os linux --arch ${image_arch}
        fi

        # Push tagged arch/ver docker manifest
        DOCKER_CLI_EXPERIMENTAL=enabled docker manifest push ${repo}:${docker_arch}-${ver}-${TRAVIS_BRANCH}
    else
        echo "Skipping version specific and latest tag docker manifest annotation... Not configured to deploy images/manifests to DockerHub"
    fi
done

# Check if build should be deployed
if [ "$TRAVIS_BRANCH" = "master" ] && [ "${TRAVIS_PULL_REQUEST}" = "false" ]; then
    # Push version specific docker manifest
    DOCKER_CLI_EXPERIMENTAL=enabled docker manifest push ${repo}:${ver}

    # Push latest docker manifest
    DOCKER_CLI_EXPERIMENTAL=enabled docker manifest push ${repo}:latest
elif [ "$DEPLOY" = true ]; then
    # Push version specific docker manifest
    DOCKER_CLI_EXPERIMENTAL=enabled docker manifest push ${repo}:${ver}-${TRAVIS_BRANCH}

    # Push latest docker manifest
    DOCKER_CLI_EXPERIMENTAL=enabled docker manifest push ${repo}:latest-${TRAVIS_BRANCH}
else
    echo "Skipping version specific and latest tag docker manifest push... Not configured to deploy images/manifests to DockerHub"
fi
```

## Docker Manifest 

The `docker manifest` command by itself performs no action, in theory it's `null`. In order to operate on a manifest or manifest list, one of the subcommands must be used.

A single manifest is information about an image, such as `layers`, `size`, and `digest`. The docker manifest command also gives users additional information such as the `OS` and `arch` an image was built for:

![Manifest](manifest.png)

> When I ran `docker manifest inspect`, usage manuals can be key -- but in this lengthy "how-to", there's no need for them. 

## Docker manifest inspect (verbose)

When setting `docker manifest inspect` with a `verbose` flag, it's going to be showing you a bit more information. So I've displayed this in the following screenshot with the `manifests` highlighted. 

![Verbose](manifest_build.png)

> We are pulling from `lucashalbert/curl` for multiarch goodness. 

Alternatively you can `grep` the `manifests`. As you can see though, they are in the logs, with a passing build. Just to see how other images work, we will show you the `ppc64le/node` image `manifest`: 

![ppc64lenode](ppc64lenode.png)

> We are pulling from ppc64le/node in DockerHub.

In both cases, you get reliable results, pulling from various images you can expect the same thing. 

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
> Bash script I edited heavily that shows off qemu, more `docker manifest` options and along with multiarch builds. 

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
docker manifest annotate 00.00.00.000:5000/cool-ibm-test:v1 00.00.00.00:5000/cool-ibm-test --arch ppc64le, s390x
```

In this example, the only `archs` that are going to be building is: 

```bash
ppc64le
s390x
```
So for example, you'd run:

```bash
docker manifest inspect cool-ibm-test:v1
 ```
Then this is what the output you'd expect to see, `s390x` along with `ppc64le` for architectures. You can also see `os`, `digest` and of course the `sha256` hash.

## Inspect a manifest list (`cool-ibm-test`) 

```json
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

The Docker container `manifest` is a file that contains data about a container image. Specifically `digest`, `sha256`, and of course `arch`. We can create a `manifes`t which points to images for different architectures so that when using the image on a particular architecture Docker automatically pulls the desired image. The reason for `manifest` is to mainly cross-build docker images.

```export DOCKER_CLI_EXPERIMENTAL=enabled # crucial for manifest to work 

docker manifest create IBM/ibm-image:latest \
            IBM/ibm-image:latest-${PLATFORM_1} \ # arch s390x (one can assume)
            IBM/ibm-image:latest-${PLATFORM_2} \ # arch ppc64le (one can assume)
            
docker manifest annotate IBM/ibm-image:latest IBM/ibm-image:latest-${PLATFORM_1} --arch ${PLATFORM_1} # arch s390x (one can assume) 
docker manifest annotate IBM/ibm-image:latest IBM/ibm-image:latest-${PLATFORM_2} --arch ${PLATFORM_2} # arch ppc64le (one can assume)

docker manifest push IBM/ibm-image:latest
```
> How `manifest` is used. You first enable experimental CLI functions, create your image, push, then as you can see two archs - `s390x`, and `ppc64le`. 


![History](history.png)

### Author(s)
Montana Mendy - [Montana](https://github.com/Montana) (Rails Engineer/DevRel @ Travis CI) 
