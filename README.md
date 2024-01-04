# kube-prometheus

A customised version of [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus) that I run on my home server.

## Disclaimer
I am not a DevOps Engineer and this isn't battle tested production code.
Use at your own risk.

## Setup
- [Install go](https://go.dev/doc/install)
- [Install jsonnet](https://github.com/google/go-jsonnet)
- [Install jsonnet-builder](https://github.com/jsonnet-bundler/jsonnet-bundler#install)
- [Install go yaml to json](https://github.com/brancz/gojsontoyaml)
- Run `jb install`

## Build
- Modify `main.jsonnet` to have the correct NFS server setup.
- Run `./build.sh`

## Deploy
```
kubectl apply -f manifests/setup --server-side
kubectl apply -f manifests/
```

## Delete
```
kubectl delete --ignore-not-found=true -f manifests/ -f manifests/setup
```

## Useful links
- [Customising kube prometheus](https://github.com/prometheus-operator/kube-prometheus/blob/main/docs/customizing.md)


