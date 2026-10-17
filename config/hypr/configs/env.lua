-- Environment variables, exported before the display server initializes.

hl.env("XCURSOR_THEME", "WhiteSur-cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.env("NVD_BACKEND", "direct")

hl.env("AQ_DRM_DEVICES", "/dev/dri/card1")

hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("QT_SCALE_FACTOR", "1.5")
hl.env("QT_FONT_DPI", "144")
hl.env("QT_QPA_PLATFORM", "wayland")

-- Qt theming (modules/home/linux/qt.nix). Set here because home-manager's
-- session variables do not reach apps launched from Hyprland.
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_PLUGIN_PATH", os.getenv("HOME") .. "/.nix-profile/lib/qt-6/plugins")
