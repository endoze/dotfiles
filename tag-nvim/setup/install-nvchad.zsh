#!/usr/bin/env zsh

set +e

NVCHAD_DIR_PATH=$HOME/.config/nvim
CHADRC_DIR_PATH=$NVCHAD_DIR_PATH/lua/custom
LSP_LANGUAGES_DIR_PATH=$CHADRC_DIR_PATH/plugins

# check for nvchad git clone
if [[ -f "$NVCHAD_DIR_PATH/init.lua" ]]; then
  echo "nvchad already cloned"
else
  pushd $NVCHAD_DIR_PATH
  git init
  git remote add origin https://github.com/nvchad/nvchad
  git fetch
  git reset --mixed origin/main
  git checkout -- .
  popd
fi

# check for existing chadrc.lua
if [[ -f "$CHADRC_DIR_PATH/chadrc.lua" ]]; then
  echo "chadrc.lua already exists"
else
  cp $CHADRC_DIR_PATH/chadrc-example.lua $CHADRC_DIR_PATH/chadrc.lua
fi

# check for existing lsplanguages.lua
if [[ -f "$LSP_LANGUAGES_DIR_PATH/lsplanguages.lua" ]]; then
  echo "lsplanguages.lua already exists"
else
  cp $LSP_LANGUAGES_DIR_PATH/lsplanguages-example.lua $LSP_LANGUAGES_DIR_PATH/lsplanguages.lua
fi

cargo install stylua
npm install -g @fsouza/prettierd
luarocks install luacheck

set -e
