{ ... }:

# nixpkgs builds swiftformat from source and lags upstream releases. Use the
# prebuilt macOS binary from the GitHub release instead, so nothing compiles.
let
  version = "0.64.1";
in
{
  nixpkgs.overlays = [
    (final: prev: {
      swiftformat = prev.stdenvNoCC.mkDerivation {
        pname = "swiftformat";
        inherit version;

        src = prev.fetchurl {
          url = "https://github.com/nicklockwood/SwiftFormat/releases/download/${version}/swiftformat.zip";
          hash = "sha256-DldiqEjXOGAsepg7JoEgMeY02F41fbBwloucgF8lPv8=";
        };

        nativeBuildInputs = [ prev.unzip ];
        sourceRoot = ".";

        installPhase = ''
          install -Dm755 swiftformat $out/bin/swiftformat
        '';

        meta = prev.swiftformat.meta // {
          platforms = prev.lib.platforms.darwin;
          sourceProvenance = [ prev.lib.sourceTypes.binaryNativeCode ];
        };
      };
    })
  ];
}
