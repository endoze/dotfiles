export LSCOLORS=ExFxCxDxBxegedabagacad
export CLICOLOR="YES"
export DOTFILES=$HOME/.dotfiles
export EDITOR="nvim"
export STARSHIP_LOG=error
export XDG_CONFIG_HOME=$HOME/.config
export RUBY_YJIT_ENABLE=1

for f in $HOME/.config/fish/aliases/*fish
  source $f
end

if test -e ~/.localrc.fish
  source ~/.localrc.fish
end

if status is-interactive && command -v starship >/dev/null 2>&1
  # stop visual bell from doing anything
  printf "\e[?1042l"

  set -l starship_cache $HOME/.cache/fish/starship-init.fish
  set -l starship_bin (command -v starship)

  if not test -f $starship_cache
      or test $starship_bin -nt $starship_cache
    test -d (dirname $starship_cache); or mkdir -p (dirname $starship_cache)
    starship init fish --print-full-init >$starship_cache
  end
  source $starship_cache
end
