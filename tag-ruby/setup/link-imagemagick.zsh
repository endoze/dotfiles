#!/usr/bin/env zsh

set +e

if host_os_is_macos; then
  brew link --force imagemagick@6
elif host_os_is_linux; then
  echo "Skipping Homebrew link of imagemagick@6 as we are on Linux."
fi

set -e
