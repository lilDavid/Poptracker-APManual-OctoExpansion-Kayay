#!/bin/sh

mkdir -p output

OUTPUT="APManual-OctoExpansion-Kayay.zip"

rm -f "$OUTPUT"
rm -rf output/*

files="images items layouts locations maps scripts var_* manifest.json settings.json"
cp -r $files output

cd output
zip -r "../$OUTPUT" * -x "**/.DS_Store"
