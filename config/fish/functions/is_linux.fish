function is_linux --description "Check if running on Linux"
  test (uname -s) = "Linux"
end
