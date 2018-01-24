#!/bin/bash
for f in `ls ./core/*.gyb`
do
    echo "Processing $f"
    name=${f%.gyb}
    ./utils/gyb -D CMAKE_SIZEOF_VOID_P=8 -o $name $f --line-directive ""
done