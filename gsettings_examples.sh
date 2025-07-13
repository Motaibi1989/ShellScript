#!/bin/bash

# --------------------------------------------
# GNOME Desktop Background Settings - Full Guide
# Author: Mohammed Alotaibi (motaibi1989.com)
# Last Update: 2025-07-13
# --------------------------------------------


# 1. Basic Wallpaper Settings
# ---------------------------

# Light mode wallpaper (GNOME 42+ uses this in light theme)
gsettings set org.gnome.desktop.background picture-uri 'file:///home/username/Pictures/wallpaper.jpg'

# Dark mode wallpaper (used in dark theme only, GNOME 42+)
gsettings set org.gnome.desktop.background picture-uri-dark 'file:///home/username/Pictures/wallpaper-dark.jpg'

# Set how the wallpaper is displayed
# Options: none | wallpaper | centered | scaled | stretched | zoom | spanned
gsettings set org.gnome.desktop.background picture-options 'zoom'

# 2. Solid Color Background (No Image)
# ------------------------------------

# Set the primary background color (hex format)
gsettings set org.gnome.desktop.background primary-color '#3465a4'

# Set secondary color (used with gradients)
gsettings set org.gnome.desktop.background secondary-color '#204a87'

# Shading type for color gradient
# Options: solid | horizontal | vertical
gsettings set org.gnome.desktop.background color-shading-type 'vertical'

# 3. Lock Screen Background
# -------------------------

# Set lock screen wallpaper (GNOME 3.28+)
gsettings set org.gnome.desktop.screensaver picture-uri 'file:///home/username/Pictures/lockscreen.jpg'

# Lock screen display style (same options as desktop)
gsettings set org.gnome.desktop.screensaver picture-options 'scaled'

# 4. Dynamic Rendering Settings
# -----------------------------

# Enable or disable rendering of desktop background
gsettings set org.gnome.desktop.background draw-background true

# Enable or disable desktop icons (note: GNOME 3.28+ uses extensions)
# Deprecated in GNOME Shell; may require 'gnome-shell-extension-desktop-icons-ng'
#gsettings set org.gnome.desktop.background show-desktop-icons true

# 5. Timed Wallpapers (Dynamic)
# -----------------------------

# Set an XML timed wallpaper (requires gnome-backgrounds or your own .xml)
gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/gnome/adwaita-timed.xml'

# Set rotation interval in seconds (if supported by XML)
gsettings set org.gnome.desktop.background picture-rotation-interval 600

# 6. Multi-Monitor Setup
# ----------------------

# For spanning one wallpaper across all screens
gsettings set org.gnome.desktop.background picture-options 'spanned'

# NOTE: GNOME does not officially support per-monitor wallpapers via gsettings
# The below array is conceptual and not functional out-of-the-box
#gsettings set org.gnome.desktop.background picture-uri "['file:///path/monitor1.jpg', 'file:///path/monitor2.jpg']"

# 7. Reset to Defaults
# --------------------

# Reset wallpaper path to default
gsettings reset org.gnome.desktop.background picture-uri

# Reset all background-related settings to GNOME defaults
gsettings reset-recursively org.gnome.desktop.background
gsettings reset-recursively org.gnome.desktop.screensaver

# ============================================
# End of GNOME Background Configuration Script
# ============================================
