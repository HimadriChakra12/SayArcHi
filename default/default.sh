echo "Creating ~/.xinitrc if missing..."
if [ ! -f ~/.xinitrc ]; then
  echo "exec i3" > ~/.xinitrc
  echo "~/.xinitrc created with 'exec i3'"
else
  echo "~/.xinitrc already exists. Make sure it has 'exec i3'"
fi

echo "Creating local .desktop entries if missing..."

mkdir -p ~/.local/share/applications

# firefox.desktop
if [ ! -f ~/.local/share/applications/firefox.desktop ]; then
  echo "Creating firefox.desktop..."
  cat > ~/.local/share/applications/firefox.desktop <<EOF
[Desktop Entry]
Name=Firefox
Exec=firefox %u
Type=Application
Icon=firefox
Terminal=false
Categories=Network;WebBrowser;
MimeType=x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
EOF
fi

# nemo.desktop
if [ ! -f ~/.local/share/applications/nemo.desktop ]; then
  echo "Creating nemo.desktop..."
  cat > ~/.local/share/applications/nemo.desktop <<EOF
[Desktop Entry]
Name=Nemo
Exec=nemo %U
Type=Application
Icon=folder
Terminal=false
Categories=System;FileTools;FileManager;
MimeType=inode/directory;
EOF
fi

echo "Setting default applications..."

# Browser
xdg-settings set default-web-browser firefox.desktop
echo "Firefox set as default browser"

# Qimgv as image viewer
echo "Setting Qimgv as default image viewer..."
for mime in image/jpeg image/png image/gif image/webp image/svg+xml; do
  xdg-mime default qimgv.desktop "$mime"
done

# MPV as video player
echo "Setting MPV as default video player..."
for mime in video/mp4 video/x-matroska video/x-msvideo video/webm; do
  xdg-mime default mpv.desktop "$mime"
done

# Rhythmbox as music player
echo "Setting Rhythmbox as default music player..."
for mime in audio/mpeg audio/x-wav audio/ogg audio/flac; do
  xdg-mime default rhythmbox.desktop "$mime"
done

# Nemo as file manager
xdg-mime default nemo.desktop inode/directory
xdg-settings set default-file-manager nemo.desktop
echo "Nemo set as default file manager"

echo "All defaults configured successfully!"
