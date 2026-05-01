# Async direnv hook to avoid blocking prompt on cold nix evals
# See: https://github.com/nix-community/nix-direnv/issues/292

if status is-interactive && command -v direnv >/dev/null 2>&1
  function __direnv_export_eval --on-event fish_prompt
      set -l prev_status $status
      if set -q __direnv_async_file
          if test -f $__direnv_async_file
              source $__direnv_async_file 2>/dev/null
          end
          rm -f $__direnv_async_file
          set -e __direnv_async_file
      end
      set -g __direnv_async_file (mktemp /tmp/direnv.XXXXXXXXXX)
      command direnv export fish >$__direnv_async_file 2>/dev/null </dev/null &
      disown
      return $prev_status
  end

  function __direnv_cd_hook --on-variable PWD
      set -g __direnv_async_file (mktemp /tmp/direnv.XXXXXXXXXX)
      command direnv export fish >$__direnv_async_file 2>/dev/null </dev/null &
      disown
  end
end
