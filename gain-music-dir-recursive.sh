#!/bin/bash

# gain-music-dir-recursive.sh: A script to apply replaygain to an
# entire directory tree (or several).

# Usage: gain-music-dir-recursive.sh [paths...]
# Supply one or more paths in which to apply replaygain to all music files.

# This determines what the script does when run with no arguments
DEFAULT_MUSIC_DIR="~/Music/for-export" # You can set this to your music folder

if [ -z "$(echo $@)" ]; then
  set $DEFAULT_MUSIC_DIR
fi

record_error () {
  errors="$errors\n$@"
}

print_errors () {
  if [ -n "$errors" ]; then
    echo -ne "The following errors were encountered: $errors\n"
  fi
}

gain_general_single () {
  if [ -z "$1$2" ]; then
    echo "Invalid input: $@"
    return
  fi

  local gain_target_file="$1"
  if [ "$(echo *.$gain_extension)" = "*.$gain_extension" ]; then
    #echo "No $gain_extension files in $(pwd)."
    return
  fi

  local gain_command="$2"
  local gain_track_opt="$3"

  local gain_opt="$gain_track_opt"

  echo "Running $gain_command $gain_opt \"$gain_target_file\" in $(pwd)"
  $gain_command $gain_opt "$gain_target_file" || record_error "In $(pwd):\n  Failed to run: $gain_command $gain_opt \"$gain_target_file\".\n  This file was not gained."
}

test_executable () {
  if which $(echo $1 | sed -e 's/ .*//') &>/dev/null; then
    return 0; #true
  else
    return 1; #false
  fi
}

gain_general () {
  if [ -z "$1$2" ]; then
    echo "Invalid input: $@"
    return
  fi

  local gain_extension=$1
  if [ "$(echo *.$gain_extension)" = "*.$gain_extension" ]; then
    #echo "No $gain_extension files in $(pwd)."
    return
  fi

  local gain_command=$2
  local gain_track_opt=$3
  local gain_album_opt=$4

  # Test for executability of the replaygain program
  test_executable $gain_command || {
    record_error "Unable to gain $gain_extension files because $(echo $gain_command | sed -e 's/ .*//') is not installed.";
    return;
  }

  local gain_opt="$gain_track_opt"
  if [ -f "ALBUMGAIN" ]; then
    local gain_opt="$gain_album_opt"
  fi

  echo "Running $gain_command $gain_opt *.$gain_extension in $(pwd)"
  $gain_command $gain_opt *.$gain_extension || {
    record_error "In $(pwd):\n  Failed to run: $gain_command $gain_opt *.$gain_extension\n  Falling back to one-track-at-a-time replaygain.";
    shift;
    local target;
    for target in *.$gain_extension; do
      gain_general_single "$target" "$@";
    done
  };
}

# These
gain_mp3 () {
  gain_general mp3 "mp3gain -k -p" "-r" "-a";
}

gain_ogg () {
  gain_general ogg "vorbisgain -a -s";
}

gain_flac () {
  gain_general flac "metaflac --add-replay-gain --preserve-modtime";
}

gain_wv () {
  gain_general wv "wvgain -a";
}

gain_aac () {
  gain_general aac "aacgain -k -p" "-r" "-a";
  gain_general mp4 "aacgain -k -p" "-r" "-a";
}



gain_dir () {
  echo "Adding replaygain to known file types in $(pwd)"
  gain_mp3
  gain_ogg
  gain_flac
  gain_wv
  gain_aac
  echo "Finished adding replaygain in $(pwd)"
}

gain_dir_recursive () {
  gain_dir
  if [ "$(echo */)" != "*/" ]; then
    local dir
    for dir in */; do
      pushd "$dir";
      gain_dir_recursive
      popd;
    done
  fi
}

for dir in "$@"; do
  pushd "$dir"
  gain_dir_recursive
  popd;
done

print_errors
