#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -eq 0 ]]; then
echo "Do not run this script as root. Run it as a regular user with sudo privileges." >&2
exit 1
fi

REPO_URL="https://github.com/ratto-101/hypr-dots.git"
DOTFILES_DIR="${HOME}/.local/share/hypr-dots"
BACKUP_DIR="${HOME}/.config-backup-$(date +%Y%m%d-%H%M%S)"

echo "==> Installing base git & base-devel..."
sudo pacman -S --needed --noconfirm git base-devel

if [[ -d "${DOTFILES_DIR}/.git" ]]; then
echo "==> Updating existing repo in ${DOTFILES_DIR}..."
git -C "${DOTFILES_DIR}" pull --ff-only
else
echo "==> Cloning ${REPO_URL} into ${DOTFILES_DIR}..."
rm -rf "${DOTFILES_DIR}"
git clone "${REPO_URL}" "${DOTFILES_DIR}"
fi

echo "==> Normalizing user home paths in ${DOTFILES_DIR}..."
find "${DOTFILES_DIR}" -path '*/.git' -prune -o -type f -exec grep -Il "/home/ratto" {} + \
  | xargs -r sed -i "s|/home/ratto|${HOME}|g"

if [[ -f "${DOTFILES_DIR}/packages.txt" ]]; then
mapfile -t PACMAN_PKGS < <(grep -vE '^\s*(#|$)' "${DOTFILES_DIR}/packages.txt" || true)
if [[ "${#PACMAN_PKGS[@]}" -gt 0 ]]; then
echo "==> Installing official packages..."
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"
fi
fi

if [[ -f "${DOTFILES_DIR}/aur-packages.txt" ]]; then
if ! command -v yay >/dev/null 2>&1; then
echo "==> Installing yay..."
tmp_yay="$(mktemp -d)"
git clone https://aur.archlinux.org/yay.git "${tmp_yay}/yay"
(cd "${tmp_yay}/yay" && makepkg -si --noconfirm)
rm -rf "${tmp_yay}"
fi
mapfile -t AUR_PKGS < <(grep -vE '^\s*(#|$)' "${DOTFILES_DIR}/aur-packages.txt" || true)
if [[ "${#AUR_PKGS[@]}" -gt 0 ]]; then
echo "==> Installing AUR packages..."
yay -S --needed --noconfirm "${AUR_PKGS[@]}"
fi
fi

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

install_brave_origin

mkdir -p "${BACKUP_DIR}/config" "${BACKUP_DIR}/local-bin" "${BACKUP_DIR}/themes" "${BACKUP_DIR}/icons" "${BACKUP_DIR}/home"
mkdir -p "${HOME}/.config" "${HOME}/.local/bin" "${HOME}/.local/share/themes" "${HOME}/.local/share/icons"

link_dir_items() {
local src_dir="$1"
local dst_dir="$2"
local bak_dir="$3"
local skip_name="${4:-}"

[[ -d "${src_dir}" ]] || return 0
shopt -s dotglob nullglob
for item in "${src_dir}"/*; do
local name
name="$(basename "${item}")"
[[ -n "${skip_name}" && "${name}" == "${skip_name}" ]] && continue
local target="${dst_dir}/${name}"
if [[ -e "${target}" || -L "${target}" ]]; then
mv "${target}" "${bak_dir}/"
fi
ln -s "${item}" "${target}"
done
shopt -u dotglob nullglob
}

echo "==> Backing up existing configs and creating symlinks..."
link_dir_items "${DOTFILES_DIR}/config" "${HOME}/.config" "${BACKUP_DIR}/config"
link_dir_items "${DOTFILES_DIR}/local-bin" "${HOME}/.local/bin" "${BACKUP_DIR}/local-bin" "bluetooth-menu"
link_dir_items "${DOTFILES_DIR}/themes" "${HOME}/.local/share/themes" "${BACKUP_DIR}/themes"
link_dir_items "${DOTFILES_DIR}/icons" "${HOME}/.local/share/icons" "${BACKUP_DIR}/icons"

if [[ -d "${DOTFILES_DIR}/home" ]]; then
shopt -s dotglob nullglob
for item in "${DOTFILES_DIR}/home"/*; do
dot_name="$(basename "${item}")"
dot_target="${HOME}/.${dot_name}"
if [[ -e "${dot_target}" || -L "${dot_target}" ]]; then
mv "${dot_target}" "${BACKUP_DIR}/home/"
fi
ln -s "${item}" "${dot_target}"
done
shopt -u dotglob nullglob
fi

rmdir "${BACKUP_DIR}/config" "${BACKUP_DIR}/local-bin" "${BACKUP_DIR}/themes" "${BACKUP_DIR}/icons" "${BACKUP_DIR}/home" "${BACKUP_DIR}" 2>/dev/null || true

echo "==> Done! Log out and back into Hyprland to apply everything."
