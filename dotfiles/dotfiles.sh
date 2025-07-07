git clone https://github.com/HimadriChakra12/.dotfiles.git ~/.dotfiles

dotfiles=(
  "$HOME/.dotfiles/i3:$HOME/.config/i3"
  "$HOME/.dotfiles/rofi:$HOME/.config/rofi"
  "$HOME/.dotfiles/dunst:$HOME/.config/dunst"
  "$HOME/.dotfiles/gh:$HOME/.config/gh"
  "$HOME/.dotfiles/mpv:$HOME/.config/mpv"
  "$HOME/.dotfiles/nvim:$HOME/.config/nvim"
  "$HOME/.dotfiles/qimgv:$HOME/.config/qimgv"
  "$HOME/.dotfiles/wezterm:$HOME/.config/wezterm"
  "$HOME/.dotfiles/.bashrc:$HOME/.bashrc"
  "$HOME/.dotfiles/.tmux.conf:$HOME/.tmux.conf"
)

echo "Linking dotfiles..."
for entry in "${dotfiles[@]}"; do
  src="${entry%%:*}"
  tgt="${entry##*:}"
  echo "Linking $src → $tgt"
  ln -sf "$src" "$tgt"
done

