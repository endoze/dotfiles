# Copy this file to users.local.nix and fill in your details
# users.local.nix is git-ignored and won't be committed
# This single configuration is used by all machine profiles
{
  username = "your-username"; # MUST be your actual username (run 'whoami' to check)
  fullName = "Your Name";
  userEmail = "your-email@example.com";
  gpgKey = ""; # optional GPG key ID

  # System configuration
  hostName = "your-hostname";
  computerName = "Your Computer Name"; # macOS only, ignored on Linux
}
