# ANTIGEN SETUP

if host_os_is_macos; then
  source $(brew --prefix)/share/antigen/antigen.zsh
elif host_os_is_linux; then
  ANTIGEN_LIBRARY_PATH=~/.dotfiles/antigen-library.zsh

  if [[ ! -a $ANTIGEN_LIBRARY_PATH ]]; then
    curl -L git.io/antigen > $ANTIGEN_LIBRARY_PATH
  fi

  source $ANTIGEN_LIBRARY_PATH
fi


antigen use oh-my-zsh

antigen bundles <<EOBUNDLES
  git
  rails
  bundler
  unixorn/fzf-zsh-plugin@main
EOBUNDLES

antigen theme bira

antigen apply
