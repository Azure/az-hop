#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

text=$1
tmpfile=$SCRIPT_DIR/azhop_$text.png
#tmpfiletext=tmp-azhop-${text}-text.png
#tmpfile=tmp-azhop-${text}-orig.png
#convert -background transparent -size 512x512 -stroke white -strokewidth 5 -fill blue -pointsize 156 -font Century-Schoolbook-L-Bold -gravity center label:"$text" $tmpfiletext
#convert -composite -gravity center $SCRIPT_DIR/logo.png $tmpfiletext $tmpfile

convert $tmpfile -resize 216x216 -gravity center -background transparent -extent 216x216 azhop-${text}-large.png
convert $tmpfile -resize 90x90 -gravity center -background transparent -extent 90x90 azhop-${text}-medium.png
convert $tmpfile -resize 48x48 -gravity center -background transparent -extent 48x48 azhop-${text}-small.png
convert $tmpfile -resize 255x155 -gravity center -background transparent -extent 255x155 azhop-${text}-wide.png

