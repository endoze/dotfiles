function wt
    switch $argv[1]
        case switch remove
            set -l __wt_out (command jjwt $argv[1] $argv[2..])
            or return $status
            set -l __wt_cd ""
            set -l __wt_exec ""
            for line in $__wt_out
                set -l prefix (string sub -l 3 -- $line)
                if test "$prefix" = "cd:"
                    set __wt_cd (string sub -s 4 -- $line)
                else if test (string sub -l 5 -- $line) = "exec:"
                    set __wt_exec (string sub -s 6 -- $line)
                else if test -z "$__wt_cd" -a -n "$line" -a -d "$line"
                    set __wt_cd $line
                end
            end
            if test -n "$__wt_cd" -a -d "$__wt_cd"
                cd "$__wt_cd"
            end
            if test -n "$__wt_exec"
                eval $__wt_exec
            end
        case '*'
            command jjwt $argv
    end
end
