export DOTFILES=$HOME/.dotfiles
export EDITOR="nvim"
export RCRC=$DOTFILES/rcrc

# --files: List files that would be searched but do not search
# --no-ignore: Do not respect .gitignore, etc...
# --hidden: Search hidden files and folders
# --follow: Follow symlinks
# --glob: Additional conditions for search (in this case ignore everything in the .git/ folder, target/ folder, and hidden files that start with _)

export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!.git/*" --glob "!target/*" --glob "!._*"'b
