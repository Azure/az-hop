#!/bin/bash
set -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd $DIR
buildenv=${1:-local}
login_server=$2

tag=$(date +"%g%m.%d%H")
case "$buildenv" in
    "github")
        hpcrover="hpcrover:${tag}"
        latest="hpcrover:latest"
    ;;

    "local")
        hpcrover="hpcrover:${tag}"
    ;;
esac


echo "Creating version ${hpcrover}"

# Build the base image
#docker-compose build 
docker build . -t ${login_server}/${hpcrover}

#docker tag toolset_hpcrover ${hpcrover}
case "$buildenv" in
    "github")
        docker login ${login_server}
        docker tag ${login_server}/${hpcrover} ${login_server}/${latest}
        docker push ${login_server}/${latest}
    ;;

    "local")
    ;;
esac

echo "Version ${hpcrover} created."
popd