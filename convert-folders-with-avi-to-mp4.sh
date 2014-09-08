#!/bin/bash
find /path/to/folder/ -iname '*.avi' -print0 | while read -d '' -r file; do
    ffmpeg -i "$file" -c:v copy -c:a copy ${file%%.avi}.mp4
done
