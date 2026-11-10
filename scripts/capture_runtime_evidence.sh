#!/bin/bash
set -e

mkdir -p review_screenshots

SCREENS=(
  "home:01_home_screen.png"
  "gallery:02_gallery_screen.png"
  "camera:03_camera_screen.png"
  "editor:04_editor_canvas.png"
  "crop:05_crop_screen.png"
  "adjust:06_adjust_panel.png"
  "filter:07_filter_panel.png"
  "curves:08_curves_panel.png"
  "effects:09_effects_panel.png"
  "presets:10_presets_screen.png"
  "export:11_export_screen.png"
  "settings:12_settings_screen.png"
  "profile:13_profile_screen.png"
)

# Function to get window id
get_window_id() {
  swift -e '
import Cocoa
let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] ?? []
for w in windowList {
    if let owner = w[kCGWindowOwnerName as String] as? String, owner.lowercased().contains("lumafix") {
        print("\(w[kCGWindowNumber as String] ?? 0)")
        break
    }
}
'
}

for item in "${SCREENS[@]}"; do
  SCREEN="${item%%:*}"
  OUTFILE="review_screenshots/${item##*:}"
  
  echo "Capturing screen: $SCREEN -> $OUTFILE"
  killall lumafix 2>/dev/null || true
  sleep 1
  
  open -n build/macos/Build/Products/Debug/lumafix.app --args --screen="$SCREEN"
  sleep 3
  
  WID=$(get_window_id)
  if [ -n "$WID" ] && [ "$WID" -gt 0 ]; then
    screencapture -l"$WID" "$OUTFILE"
    echo "  Captured window $WID to $OUTFILE ($(ls -lh "$OUTFILE" | awk '{print $5}'))"
  else
    echo "  Failed to find window for $SCREEN"
  fi
  
  killall lumafix 2>/dev/null || true
  sleep 1
done

echo "All screenshots captured successfully!"
