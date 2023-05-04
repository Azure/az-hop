#!/bin/bash

build_dir=azhop_$(date +"%Y%m%d_%H%M%S")
mkdir $build_dir
echo "Converting YAML config to JSON"
yq -o=json <marketplace_config.yml >$build_dir/config.json
echo "Embedding config into createUiDefinition.json"
jq --argfile azhopConfig $build_dir/config.json '.parameters.outputs.azhopConfig += $azhopConfig' ui_definition.json > $build_dir/createUiDefinition.json
rm $build_dir/config.json
echo "Converting Bicep to ARM template"
az bicep build --file ../../bicep/mainTemplate.bicep --outdir $build_dir
echo "Adding tracking resource to ARM template"
jq --argfile trackingResource tracking_resource.json '.resources += [$trackingResource]' $build_dir/mainTemplate.json > $build_dir/mainTemplateTracking.json
mv $build_dir/mainTemplateTracking.json $build_dir/mainTemplate.json
echo "Creating zipfile"
pushd $build_dir
zip -r ../$build_dir.zip *
popd