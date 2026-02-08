{ config, pkgs, lib, ... }:

let
  alerterBinary = pkgs.buildGoModule {
    pname = "alerter";
    version = "2.0.0";

    src = pkgs.fetchFromGitHub {
      owner = "vjeantet";
      repo = "alerter";
      rev = "dd43ae2dad988c2a3117a459bc567741c278e640";
      sha256 = "08dq9iw2x28l7avvqnmk1ivrlp3bn66a4nv6mdwqfbg8ckqib2hb";
    };

    vendorHash = null;

    # UserNotifications requires macOS 10.14+ SDK
    buildInputs = lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
      pkgs.apple-sdk_14
    ];

    meta = with lib; {
      description = "Send User Alert Notification on Mac OS X from the command-line";
      homepage = "https://github.com/vjeantet/alerter";
      license = licenses.mit;
      platforms = platforms.darwin;
    };
  };

  # Wrap the binary in an app bundle so UNUserNotificationCenter works
  alerter = pkgs.stdenv.mkDerivation {
    pname = "alerter-app";
    version = "2.0.0";

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/Applications/Alerter.app/Contents/MacOS
      mkdir -p $out/Applications/Alerter.app/Contents/Resources

      cp ${alerterBinary}/bin/alerter $out/Applications/Alerter.app/Contents/MacOS/alerter

      cat > $out/Applications/Alerter.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleIdentifier</key>
  <string>com.github.vjeantet.alerter</string>
  <key>CFBundleName</key>
  <string>Alerter</string>
  <key>CFBundleDisplayName</key>
  <string>Alerter</string>
  <key>CFBundleExecutable</key>
  <string>alerter</string>
  <key>CFBundleVersion</key>
  <string>2.0.0</string>
  <key>CFBundleShortVersionString</key>
  <string>2.0.0</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>10.14</string>
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
EOF

      mkdir -p $out/bin
      ln -s $out/Applications/Alerter.app/Contents/MacOS/alerter $out/bin/alerter
    '';

    meta = with lib; {
      description = "Send User Alert Notification on Mac OS X from the command-line";
      homepage = "https://github.com/vjeantet/alerter";
      license = licenses.mit;
      platforms = platforms.darwin;
    };
  };

  # Codesigned copy in a mutable location for notifications to work
  alerterSigned = pkgs.writeShellScriptBin "alerter" ''
    ALERTER_APP="$HOME/.local/share/Alerter.app"
    ALERTER_BIN="$ALERTER_APP/Contents/MacOS/alerter"

    # Check if we need to copy/sign the app
    if [ ! -x "$ALERTER_BIN" ] || [ "${alerter}" -nt "$ALERTER_BIN" ]; then
      rm -rf "$ALERTER_APP"
      cp -R "${alerter}/Applications/Alerter.app" "$ALERTER_APP"
      chmod -R u+w "$ALERTER_APP"
      /usr/bin/codesign --force --deep --sign - "$ALERTER_APP"
    fi

    exec "$ALERTER_BIN" "$@"
  '';
in
{
  home.packages = [ alerterSigned ];
}
