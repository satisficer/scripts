#!/bin/bash
find /path/to/folder -iname '*.png' -print0 | while read -d '' -r file; do
    convert -resize 50% "$file" ${file%%.png}_50pct.png
done
