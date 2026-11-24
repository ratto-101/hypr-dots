#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# install.sh — Hyprland rice installer
# =============================================================================
# Usage:
#   ./install.sh                  # full install (deps + configs)
#   ./install.sh --no-deps        # configs only, skip package install
#   ./install.sh --no-backup      # overwrite existing configs without backup
#   ./install.sh --uninstall      # remove symlinks (backups stay)
#   ./install.sh --help           # show this help
# =============================================================================

if [[ "${EUID}" -eq 0 ]]; then
    echo "Do not run this script as root. Run it as a regular user with sudo privileges." >&2
    exit 1
fi

# --- Argument parsing ---
NO_DEPS=0
NO_BACKUP=0
UNINSTALL=0
for arg in "$@"; do
    case "$arg" in
        --no-deps)     NO_DEPS=1 ;;
        --no-backup)   NO_BACKUP=1 ;;
        --uninstall)   UNINSTALL=1 ;;
        -h|--help)
            sed -n '2,/^# =/p' "$0" | sed 's/^# \?//'
            exit 0 ;;
        *) echo "Unknown arg: $arg (try --help)" >&2; exit 1 ;;
    esac
done

REPO_URL="https://github.com/ratto-101/hypr-dots.git"
DOTFILES_DIR="${HOME}/.local/share/hypr-dots"
BACKUP_DIR="${HOME}/.config-backup-$(date +%Y%m%d-%H%M%S)"

# --- Uninstall path ---
if [[ $UNINSTALL -eq 1 ]]; then
    echo "==> Uninstalling rice (removing symlinks)..."
    for src_dir in "${DOTFILES_DIR}/config" "${DOTFILES_DIR}/local-bin" "${DOTFILES_DIR}/themes" "${DOTFILES_DIR}/icons"; do
        [[ -d "$src_dir" ]] || continue
        case "$src_dir" in
            */config)     dst_dir="$HOME/.config" ;;
            */local-bin)  dst_dir="$HOME/.local/bin" ;;
            */themes)     dst_dir="$HOME/.local/share/themes" ;;
            */icons)      dst_dir="$HOME/.local/share/icons" ;;
        esac
        shopt -s nullglob
        for item in "$src_dir"/*; do
            name="$(basename "$item")"
            link="$dst_dir/$name"
            if [[ -L "$link" && "$(readlink -f "$link")" == "$item" ]]; then
                rm "$link"
                echo "  removed $link"
            fi
        done
        shopt -u nullglob
    done
    echo "==> Done. Log out of Hyprland to fully unload."
    echo "    Your backups are still in ~/.config-backup-* if you need to restore."
    exit 0
fi

# --- Install git + base-devel (only if installing deps) ---
if [[ $NO_DEPS -eq 0 ]]; then
    echo "==> Installing base git & base-devel..."
    sudo pacman -S --needed --noconfirm git base-devel
fi

# --- Clone or update repo ---
if [[ -d "${DOTFILES_DIR}/.git" ]]; then
    echo "==> Updating existing repo in ${DOTFILES_DIR}..."
    git -C "${DOTFILES_DIR}" pull --ff-only
else
    echo "==> Cloning ${REPO_URL} into ${DOTFILES_DIR}..."
    rm -rf "${DOTFILES_DIR}"
    git clone "${REPO_URL}" "${DOTFILES_DIR}"
fi

# --- Normalize hardcoded home paths (/home/ratto -> $HOME) ---
echo "==> Normalizing user home paths in ${DOTFILES_DIR}..."
find "${DOTFILES_DIR}" -path '*/.git' -prune -o -type f -print0 \
    | xargs -0 grep -IlE "/home/(ratto|test)" 2>/dev/null \
    | xargs -r sed -i -E "s|/home/(ratto|test)|${HOME}|g" || true

# --- Install dependencies ---
if [[ $NO_DEPS -eq 1 ]]; then
    echo "==> Skipping package install (--no-deps)"
else
    if [[ -f "${DOTFILES_DIR}/packages.txt" ]]; then
        mapfile -t PACMAN_PKGS < <(grep -vE '^\s*(#|$)' "${DOTFILES_DIR}/packages.txt" || true)
        if [[ "${#PACMAN_PKGS[@]}" -gt 0 ]]; then
            echo "==> Installing ${#PACMAN_PKGS[@]} official packages..."
            sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"
        fi
    fi

    if [[ -f "${DOTFILES_DIR}/aur-packages.txt" ]]; then
        # Detect AUR helper (prefer paru, then yay)
        AUR_HELPER=""
        if command -v paru >/dev/null 2>&1; then
            AUR_HELPER=paru
        elif command -v yay >/dev/null 2>&1; then
            AUR_HELPER=yay
        else
            echo "==> Installing yay (AUR helper)..."
            tmp_yay="$(mktemp -d)"
            git clone https://aur.archlinux.org/yay.git "${tmp_yay}/yay"
            (cd "${tmp_yay}/yay" && makepkg -si --noconfirm)
            rm -rf "${tmp_yay}"
            AUR_HELPER=yay
        fi

        mapfile -t AUR_PKGS < <(grep -vE '^\s*(#|$)' "${DOTFILES_DIR}/aur-packages.txt" || true)
        if [[ "${#AUR_PKGS[@]}" -gt 0 ]]; then
            echo "==> Installing ${#AUR_PKGS[@]} AUR packages via ${AUR_HELPER}..."
            $AUR_HELPER -S --needed --noconfirm "${AUR_PKGS[@]}"
        fi
    fi
fi

# --- Backup + symlink helper ---
link_dir_items() {
    local src_dir="$1"
    local dst_dir="$2"
    local bak_dir="$3"
    local skip_name="${4:-}"

    [[ -d "${src_dir}" ]] || return 0
    mkdir -p "$dst_dir" "$bak_dir"
    shopt -s dotglob nullglob
    for item in "${src_dir}"/*; do
        local name
        name="$(basename "${item}")"
        [[ -n "${skip_name}" && "${name}" == "${skip_name}" ]] && continue
        local target="${dst_dir}/${name}"
        if [[ -e "${target}" || -L "${target}" ]]; then
            if [[ $NO_BACKUP -eq 1 ]]; then
                rm -rf "${target}"
            else
                mv "${target}" "${bak_dir}/"
            fi
        fi
        ln -s "${item}" "${target}"
    done
    shopt -u dotglob nullglob
}

if [[ $NO_BACKUP -eq 1 ]]; then
    echo "==> Symlinking configs (no backup)..."
else
    echo "==> Backing up existing configs to ${BACKUP_DIR}..."
fi
mkdir -p "${BACKUP_DIR}/config" "${BACKUP_DIR}/local-bin" "${BACKUP_DIR}/themes" "${BACKUP_DIR}/icons" "${BACKUP_DIR}/home"
mkdir -p "${HOME}/.config" "${HOME}/.local/bin" "${HOME}/.local/share/themes" "${HOME}/.local/share/icons"

link_dir_items "${DOTFILES_DIR}/config"     "${HOME}/.config"             "${BACKUP_DIR}/config"
link_dir_items "${DOTFILES_DIR}/local-bin"  "${HOME}/.local/bin"          "${BACKUP_DIR}/local-bin"  "bluetooth-menu"
link_dir_items "${DOTFILES_DIR}/themes"     "${HOME}/.local/share/themes"  "${BACKUP_DIR}/themes"
link_dir_items "${DOTFILES_DIR}/icons"      "${HOME}/.local/share/icons"  "${BACKUP_DIR}/icons"

if [[ -d "${DOTFILES_DIR}/home" ]]; then
    shopt -s dotglob nullglob
    for item in "${DOTFILES_DIR}/home"/*; do
        dot_name="$(basename "${item}")"
        dot_target="${HOME}/.${dot_name}"
        if [[ -e "${dot_target}" || -L "${dot_target}" ]]; then
            if [[ $NO_BACKUP -eq 1 ]]; then
                rm -rf "${dot_target}"
            else
                mv "${dot_target}" "${BACKUP_DIR}/home/"
            fi
        fi
        ln -s "${item}" "${dot_target}"
    done
    shopt -u dotglob nullglob
fi

# Clean up empty backup dirs (if nothing was backed up)
rmdir "${BACKUP_DIR}/config" "${BACKUP_DIR}/local-bin" "${BACKUP_DIR}/themes" "${BACKUP_DIR}/icons" "${BACKUP_DIR}/home" "${BACKUP_DIR}" 2>/dev/null || true

echo
echo "==> Done! Log out and back into Hyprland to apply everything."
echo
echo "    To revert:  ./install.sh --uninstall"
echo "    To update:  ./install.sh   (re-runs git pull + re-symlinks)"
