{ pkgs, ... }:

pkgs.stdenv.mkDerivation rec {
  pname = "sddm-cyberpunk-theme";
  version = "1.0";

  src = ../config/sddm/theme/cyberpunk;

  buildInputs = with pkgs; [
    qt6.qt5compat
    qt6.qtdeclarative
  ];

  dontBuild = true;
  dontWrapQtApps = true;

  installPhase = ''
    mkdir -p $out/share/sddm/themes/cyberpunk
    cp -r * $out/share/sddm/themes/cyberpunk/

    # Copy the wallpaper into the theme directory
    cp ${../wallpapers/woman-in-cyberpunk-city.jpg} $out/share/sddm/themes/cyberpunk/backgrounds/woman-in-cyberpunk-city.jpg

    # Update the background path in theme.conf to use the wallpaper in the theme directory
    substituteInPlace $out/share/sddm/themes/cyberpunk/theme.conf \
      --replace "@BACKGROUND_PATH@" "$out/share/sddm/themes/cyberpunk/backgrounds/woman-in-cyberpunk-city.jpg"
  '';

  meta = with pkgs.lib; {
    description = "Cyberpunk SDDM theme based on Catppuccin Mocha";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}