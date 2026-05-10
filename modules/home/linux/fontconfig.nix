{ ... }:

{
  xdg.configFile."fontconfig/conf.d/10-mac-like.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <match target="font">
        <edit name="hintstyle" mode="assign"><const>hintslight</const></edit>
        <edit name="antialias" mode="assign"><bool>true</bool></edit>
        <edit name="rgba"      mode="assign"><const>none</const></edit>
        <edit name="embeddedbitmap" mode="assign"><bool>false</bool></edit>
      </match>
    </fontconfig>
  '';
}
