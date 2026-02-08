function is_macos --description "Check if running on macOS"
  test (uname -s) = "Darwin"
end
