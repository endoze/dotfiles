# Disable telemetry, analytics, and update-nag prompts across CLI tools.

set -gx HOMEBREW_NO_ANALYTICS 1
set -gx HOMEBREW_NO_ENV_HINTS 1
set -gx CHECKPOINT_DISABLE 1
set -gx DOCKER_CLI_HINTS false
set -gx DOCKER_SCAN_SUGGEST false
set -gx DOTNET_CLI_TELEMETRY_OPTOUT 1
set -gx YARN_ENABLE_TELEMETRY 0
set -gx DO_NOT_TRACK 1
set -gx NPM_CONFIG_UPDATE_NOTIFIER false
set -gx NPM_CONFIG_FUND false
set -gx GH_NO_UPDATE_NOTIFIER 1
set -gx MISE_DISABLE_HINTS 1
