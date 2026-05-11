function is_macos --description "Check if running on macOS"
  if not set -q __os_kind
    set -g __os_kind (uname -s)
  end
  test "$__os_kind" = Darwin
end
