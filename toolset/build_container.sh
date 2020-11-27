#!/bin/bash
set -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd $DIR
buildenv=${1:-local}

tag=$(date +"%g%m.%d%H")
case "$buildenv" in
    "github")
        hpcrover="xpillons/hpcrover:${tag}"
        latest="xpillons/hpcrover:latest"
    ;;

    "local")
        hpcrover="hpcrover:${tag}"
    ;;
esac


echo "Creating version ${hpcrover}"

# Build the base image
docker-compose build 

docker tag toolset_hpcrover ${hpcrover}
docker tag toolset_hpcrover ${latest}
case "$buildenv" in
    "github")
        docker login
        docker push ${hpcrover}
        docker push ${latest}
    ;;

    "local")
    ;;
esac

echo "Version ${hpcrover} created."
popd