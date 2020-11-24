#!/bin/bash
set -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd $DIR
buildenv=${1:-local}

tag=$(date +"%g%m.%d%H")
case "$buildenv" in
    "github")
        hpcrover="xpillons/hpcrover:${tag}"
    ;;

    "local")
        hpcrover="hpcrover:${tag}"
    ;;
esac


echo "Creating version ${hpcrover}"

# Build the base image
docker-compose build 

docker tag toolset_hpcrover ${hpcrover}
case "$buildenv" in
    "github")
        docker login
        docker push ${hpcrover}
    ;;

    "local")
    ;;
esac

echo "Version ${hpcrover} created."
popd