function jp -d "Push the current local bookmark to remote"
    # Try to get bookmarks from @ (current commit) first
    set -l bookmarks (jj log -r '@' -T 'bookmarks' --no-graph --color=never 2>/dev/null | string trim)
    set -l revision '@'

    # If no bookmarks at @, try @- (parent of working copy)
    if test -z "$bookmarks"
        set bookmarks (jj log -r '@-' -T 'bookmarks' --no-graph --color=never 2>/dev/null | string trim)
        set revision '@-'
    end

    if test -z "$bookmarks"
        echo "No bookmark found at @ or @-"
        echo "Tip: Make sure you've squashed your changes and have a bookmark at the current revision"
        return 1
    end

    echo "Using bookmarks from $revision"

    # Split bookmarks by whitespace
    set -l bookmark_list (string split ' ' $bookmarks)

    # Filter to only local bookmarks (exclude remote bookmarks with @)
    set -l local_bookmarks
    set -l main_master_bookmarks
    for bookmark in $bookmark_list
        # Skip empty strings
        if test -z "$bookmark"
            continue
        end

        # Skip remote bookmarks (contain @)
        if string match -q '*@*' $bookmark
            continue
        end

        # Strip the * suffix that indicates divergence from remote
        set bookmark (string replace -r '\*$' '' $bookmark)

        # Track main/master separately
        if test "$bookmark" = "main"; or test "$bookmark" = "master"
            set -a main_master_bookmarks $bookmark
        else
            set -a local_bookmarks $bookmark
        end
    end

    # If no other bookmarks exist, include main/master
    if test (count $local_bookmarks) -eq 0
        if test (count $main_master_bookmarks) -gt 0
            set local_bookmarks $main_master_bookmarks
        else
            echo "No local bookmarks found to push at $revision"
            return 1
        end
    end

    # Push each local bookmark
    for bookmark in $local_bookmarks
        echo "Pushing bookmark: $bookmark"
        jj git push --bookmark "$bookmark"
    end
end
