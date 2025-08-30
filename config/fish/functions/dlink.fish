function dlink
    set -l input_path $argv[1]

    set -l transformed_path (string replace -r "dotfiles/tag-[^/]+/" "" $input_path)
    echo "Linking $input_path to $transformed_path"
    ln -sf $input_path $transformed_path
end
