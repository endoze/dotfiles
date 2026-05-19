# Async direnv hook to avoid blocking prompt on cold nix evals
# See: https://github.com/nix-community/nix-direnv/issues/292

if status is-interactive && command -v direnv >/dev/null 2>&1
  function __direnv_export_eval --on-event fish_prompt
      set -l prev_status $status
      if set -q __direnv_async_file
          if not test -f $__direnv_async_file
              # File vanished; reset.
              set -e __direnv_async_file __direnv_async_pid
          else if string match -q '# __direnv_done_marker' <$__direnv_async_file
              # Done. Sentinel is a harmless comment when sourced.
              source $__direnv_async_file 2>/dev/null
              rm -f $__direnv_async_file
              set -e __direnv_async_file __direnv_async_pid
          else if set -q __direnv_async_pid
              and kill -0 $__direnv_async_pid 2>/dev/null
              # Background still running; recheck next prompt.
              return $prev_status
          else
              # Background gone without sentinel (killed/crashed); recover.
              rm -f $__direnv_async_file
              set -e __direnv_async_file __direnv_async_pid
          end
      end
      set -g __direnv_async_file (mktemp /tmp/direnv.XXXXXXXXXX)
      sh -c "direnv export fish 2>/dev/null; printf '\n# __direnv_done_marker\n'" >$__direnv_async_file </dev/null &
      set -g __direnv_async_pid $last_pid
      disown $__direnv_async_pid 2>/dev/null
      return $prev_status
  end
end
