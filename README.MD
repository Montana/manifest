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

Once you've added `manifest`, it's crucial to add to your `.travis.yml`: 

```yaml
script: export DOCKER_CLI_EXPERIMENTAL=enabled
```
Alternatively you can run this in your project directory tree via: 

```bash
export DOCKER_CLI_EXPERIMENTAL=enabled
```

## Manifest JSON (amd64, arm, s390x, ppc64le). 

```basj
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

More info on [docker manifest](https://docs.docker.com/engine/reference/commandline/manifest/).
