#!/bin/sh

set -x

version=`date +%Y%m%d`

docker login -u zhuoyin

docker buildx build -f yzard.Dockerfile -t zhuoyin/caddy2-xray-ui:${version} .
docker tag zhuoyin/caddy2-xray-ui:${version} zhuoyin/caddy2-xray-ui:latest

docker image push zhuoyin/caddy2-xray-ui:${version}
docker image push zhuoyin/caddy2-xray-ui:latest
