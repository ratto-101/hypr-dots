# Install Brave Origin (AUR if available, otherwise latest official Linux x64 release from GitHub)
install_brave_origin() {
  if command -v brave-origin >/dev/null 2>&1; then
    echo "==> Brave Origin is already installed."
    return 0
  fi

  if command -v yay >/dev/null 2>&1; then
    for candidate in brave-origin-bin brave-origin; do
      if yay -Si "${candidate}" >/dev/null 2>&1; then
        echo "==> Installing ${candidate} via yay..."
        yay -S --needed --noconfirm "${candidate}"
        return 0
      fi
    done
  fi

  echo "==> Installing Brave Origin from official GitHub releases..."
  local api_url="https://api.github.com/repos/brave/brave-browser/releases"
  local dl_url
  dl_url="$(curl -fsSL "${api_url}?per_page=30" \
    | grep -Eo 'https://[^"]+brave-origin[^"]*linux-amd64\.(tar\.xz|zip)' \
    | head -n 1 || true)"

  if [[ -z "${dl_url}" ]]; then
    echo "Warning: Could not auto-detect a Brave Origin Linux archive URL. Install it manually from https://brave.com/origin/" >&2
    return 0
  fi

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  curl -fL "${dl_url}" -o "${tmp_dir}/brave-origin.pkg"

  sudo rm -rf /opt/brave-origin
  sudo mkdir -p /opt/brave-origin
  if [[ "${dl_url}" == *.tar.xz ]]; then
    sudo tar -xJf "${tmp_dir}/brave-origin.pkg" -C /opt/brave-origin --strip-components=1
  else
    sudo unzip -q "${tmp_dir}/brave-origin.pkg" -d "${tmp_dir}/extracted"
    sudo cp -a "${tmp_dir}/extracted/"*/* /opt/brave-origin/ 2>/dev/null || sudo cp -a "${tmp_dir}/extracted/"* /opt/brave-origin/
  fi
  rm -rf "${tmp_dir}"

  sudo ln -sf /opt/brave-origin/brave /usr/local/bin/brave-origin

  sudo tee /usr/share/applications/brave-origin.desktop >/dev/null <<'DESKTOP'
[Desktop Entry]
Version=1.0
Name=Brave Origin
GenericName=Web Browser
Exec=/usr/local/bin/brave-origin %U
Terminal=false
Icon=/opt/brave-origin/product_logo_128.png
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
DESKTOP
}