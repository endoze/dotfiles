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
  git init -b v2.0
  git remote add origin https://github.com/nvchad/nvchad
  git fetch
  git reset --mixed origin/v2.0
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

if [[ "$(uname)" == "Darwin" ]]; then
  OS='macos'
elif [[ "$(uname)" == 'Linux' ]]; then
  OS='linux'
fi

if [[ "$(uname -m)" == 'x86_64' ]]; then
  ARCH='x86_64'
elif [[ "$(uname -m)" == 'aarch64' ]]; then
  ARCH='aarch64'
fi

if [[ -n "${ARCH+1}" ]] && [[ -n "${OS+1}" ]]; then
  STYLUA_DL_URL="https://github.com/JohnnyMorganz/StyLua/releases/download/v0.17.1/stylua-${OS}-${ARCH}.zip" 
  wget -O stylua.zip $STYLUA_DL_URL
  unzip stylua.zip
  mv stylua /usr/local/bin/
  rm stylua.zip
else
  cargo install stylua
fi

luarocks install luacheck
npm install -g @fsouza/prettierd

set -e
