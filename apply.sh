#!/bin/bash
kubectl apply --server-side -f manifests/setup
kubectl apply -f manifests/
