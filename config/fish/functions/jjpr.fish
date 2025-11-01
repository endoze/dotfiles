function jjpr -d "Create a GitHub PR for the current jujutsu bookmark"
    # Try @ first, then @-
    set -l bookmark (jj log -r '@' -T 'bookmarks' --no-graph --color=never 2>/dev/null | string trim | string split ' ' | string replace -r '\*$' '' | string match -v '*@*' | string match -v 'main' | string match -v 'master' | head -n1)

    if test -z "$bookmark"
        set bookmark (jj log -r '@-' -T 'bookmarks' --no-graph --color=never 2>/dev/null | string trim | string split ' ' | string replace -r '\*$' '' | string match -v '*@*' | string match -v 'main' | string match -v 'master' | head -n1)
    end

    if test -z "$bookmark"
        echo "No bookmark found at @ or @-"
        return 1
    end

    set output (gh pr create --head "$bookmark" --fill)
    echo $output

    set url (echo $output | grep -o 'https://github.com/[^[:space:]]*' | tr -d '\n')

    if test -n "$url"
        if is_macos
            echo $url | pbcopy
        else if is_linux
            if command -v xclip >/dev/null 2>&1
                echo $url | xclip -selection clipboard
            else if command -v xsel >/dev/null 2>&1
                echo $url | xsel --clipboard --input
            end
        end
    end
end
