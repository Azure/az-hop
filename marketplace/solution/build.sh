#!/bin/bash
set -e
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
AZHOP_ROOT=${THIS_DIR}/../..


if [ -d ${AZHOP_ROOT}/miniconda ]; then
  echo "Activating conda environment"
  source ${AZHOP_ROOT}/miniconda/bin/activate

  ansible-playbook ${THIS_DIR}/arm-ttk.yml 
fi

build_dir="${THIS_DIR}/build"
rm -rf $build_dir
mkdir -p $build_dir
echo "Converting YAML config to JSON"
yq -o=json <${THIS_DIR}/marketplace_config.yml >$build_dir/config.json
echo "Embedding config into createUiDefinition.json"
# substitutions for the logic in the createUiDefinition
# * _Xn_ is the nth octet of the baseIpAddress (string)
# * _Xni_ is the nth octet of the baseIpAddress (int)
jq --argfile azhopConfig $build_dir/config.json '.parameters.outputs.azhopConfig += $azhopConfig' ${THIS_DIR}/ui_definition.json \
    | sed "s/_X1_/first(split(steps('network').baseIpAddress,'.'))/g" \
    | sed "s/_X2_/first(skip(split(steps('network').baseIpAddress,'.'),1))/g" \
    | sed "s/_X3_/first(skip(split(steps('network').baseIpAddress,'.'),2))/g" \
    | sed "s/_X4_/last(split(steps('network').baseIpAddress,'.'))/g" \
    | sed "s/_X1i_/int(first(split(steps('network').baseIpAddress,'.')))/g" \
    | sed "s/_X2i_/int(first(skip(split(steps('network').baseIpAddress,'.'),1)))/g" \
    | sed "s/_X3i_/int(first(skip(split(steps('network').baseIpAddress,'.'),2)))/g" \
    | sed "s/_X4i_/int(last(split(steps('network').baseIpAddress,'.')))/g" \
    > $build_dir/createUiDefinition.json
rm $build_dir/config.json
echo "Converting Bicep to ARM template"
az bicep build --file ${AZHOP_ROOT}/bicep/mainTemplate.bicep --outdir $build_dir
echo "Adding tracking resource to ARM template"
jq --argfile trackingResource ${THIS_DIR}/tracking_resource.json '.resources += [$trackingResource]' $build_dir/mainTemplate.json > $build_dir/mainTemplateTracking.json
mv $build_dir/mainTemplateTracking.json $build_dir/mainTemplate.json
echo "Creating zipfile"
pushd $build_dir
zip -r $build_dir.zip *
popd