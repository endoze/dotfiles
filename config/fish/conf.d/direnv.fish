# Hybrid direnv hook: synchronous in the warm-cache fast path, async only
# when direnv takes longer than the sync window (typically a cold nix eval).
# See: https://github.com/nix-community/nix-direnv/issues/292

if status is-interactive && command -v direnv >/dev/null 2>&1
  # Max time we'll block waiting for direnv before falling back to async.
  # 12 iterations × 50ms ≈ 600ms. Warm nix-direnv flakes typically finish
  # within ~350ms; cold nix evals exceed this and run fully async.
  set -g __direnv_sync_iters 12

  function __direnv_finish_if_ready
      set -q __direnv_async_file
      or return 1
      test -f $__direnv_async_file
      or begin
          set -e __direnv_async_file __direnv_async_pid
          return 1
      end
      string match -q '# __direnv_done_marker' <$__direnv_async_file
      or return 1
      source $__direnv_async_file 2>/dev/null
      rm -f $__direnv_async_file
      set -e __direnv_async_file __direnv_async_pid
      return 0
  end

  function __direnv_load
      # Cancel any in-flight job — it's for a previous PWD.
      if set -q __direnv_async_pid
          and kill -0 $__direnv_async_pid 2>/dev/null
          kill $__direnv_async_pid 2>/dev/null
      end
      if set -q __direnv_async_file
          rm -f $__direnv_async_file
      end
      set -e __direnv_async_file __direnv_async_pid

      set -g __direnv_async_file (mktemp /tmp/direnv.XXXXXXXXXX)
      sh -c "direnv export fish 2>/dev/null; printf '\n# __direnv_done_marker\n'" >$__direnv_async_file </dev/null &
      set -g __direnv_async_pid $last_pid
      disown $__direnv_async_pid 2>/dev/null

      # Brief synchronous window for the warm-cache fast path.
      for i in (seq 1 $__direnv_sync_iters)
          if not kill -0 $__direnv_async_pid 2>/dev/null
              __direnv_finish_if_ready
              return
          end
          sleep 0.05
      end
      # Still running — let __direnv_collect pick it up on a later prompt.
  end

  function __direnv_collect --on-event fish_prompt
      set -l prev_status $status
      if set -q __direnv_async_file
          if not test -f $__direnv_async_file
              set -e __direnv_async_file __direnv_async_pid
          else if __direnv_finish_if_ready
              # sourced
          else if set -q __direnv_async_pid
              and kill -0 $__direnv_async_pid 2>/dev/null
              # still running, recheck next prompt
              return $prev_status
          else
              # background gone without a marker; recover
              rm -f $__direnv_async_file
              set -e __direnv_async_file __direnv_async_pid
          end
      end
      return $prev_status
  end

  function __direnv_on_pwd --on-variable PWD
      __direnv_load
  end

  # Initial spawn for the directory the shell started in.
  __direnv_load
end
