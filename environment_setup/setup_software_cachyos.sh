#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
cd "$SCRIPT_DIR"
source "$SCRIPT_DIR/util.sh"

if [[ $(uname -m) != x86_64 ]] || ! grep -q '^ID=cachyos$' /etc/os-release; then
    echo "This setup script supports CachyOS on x86_64." >&2
    exit 1
fi
if (( EUID == 0 )); then
    echo "Run this script as your regular user; it uses sudo when needed." >&2
    exit 1
fi
if ! command -v yay >/dev/null; then
    echo "Install yay before running this script." >&2
    exit 1
fi

git -C "$SCRIPT_DIR/.." config core.hooksPath "$SCRIPT_DIR/../scripts/githooks"

print_status_msg "Installing CachyOS packages"
sudo pacman -Syu --needed \
    base-devel bazelisk clang cmake codespell curl eigen git jdk21-openjdk \
    kcachegrind libffi libusb openssl qt6-base qt6-svg sqlite sshpass unzip \
    valgrind wget xcb-util-cursor xorg-server-xvfb
yay -S --needed gcc10 python312

"$SCRIPT_DIR/cachyos_relink_gcc.sh"

print_status_msg "Setting up Python 3.12"
sudo install -d -o "$(id -u)" -g "$(id -g)" /opt/tbotspython
if [[ -f /opt/tbotspython/pyvenv.cfg ]] &&
    ! grep -q '^version = 3\.12\.' /opt/tbotspython/pyvenv.cfg; then
    echo "/opt/tbotspython already contains a virtual environment for another Python version." >&2
    exit 1
fi
/usr/bin/python3.12 -m venv /opt/tbotspython
/opt/tbotspython/bin/python3 -m pip install --upgrade pip
if [[ -L /opt/tbotspython/bin/clang-format ]]; then
    rm /opt/tbotspython/bin/clang-format
fi
/opt/tbotspython/bin/python3 -m pip install -r ubuntu24_requirements.txt \
    'PyQt6==6.10.0' 'platformio==6.1.18' 'clang-format==14.0.6'

if [[ ! -e /opt/tbotspython/bin/jdk || -L /opt/tbotspython/bin/jdk ]]; then
    ln -sfnT /usr/lib/jvm/java-21-openjdk /opt/tbotspython/bin/jdk
fi
mkdir -p /opt/tbotspython/external_runtimes /tmp/tbots_download_cache

print_status_msg "Installing game controller and AutoReferee"
if [[ ! -x /opt/tbotspython/gamecontroller ]]; then
    install_gamecontroller x86_64
fi
if [[ ! -x /opt/tbotspython/autoReferee/bin/autoReferee ]]; then
    rm -rf /opt/tbotspython/autoReferee
    install_autoref x86_64
fi
install -m 644 "$SCRIPT_DIR/../src/software/autoref/DIV_B.txt" \
    /opt/tbotspython/autoReferee/config/geometry/DIV_B.txt

print_status_msg "Installing cross compilers and Python headers"
if [[ ! -x /opt/tbotspython/aarch64-tbots-linux-gnu/bin/aarch64-tbots-linux-gnu-gcc ]]; then
    sudo rm -rf /opt/tbotspython/aarch64-tbots-linux-gnu
    install_cross_compiler x86_64
fi
if [[ ! -f /opt/tbotspython/cross_compile_headers/include/python3.12/Python.h ||
    ! -f /opt/tbotspython/cross_compile_headers/include/python3.12/pyconfig.h ]]; then
    # CPython's cross-header configure needs the robot compiler for target checks.
    CC=/opt/tbotspython/aarch64-tbots-linux-gnu/bin/aarch64-tbots-linux-gnu-gcc \
        install_python_dev_cross_compile_headers x86_64
fi
install_python_toolchain_headers
if [[ ! -x /opt/tbotspython/arm-none-eabi-gcc/bin/arm-none-eabi-gcc ]]; then
    sudo rm -rf /opt/tbotspython/arm-none-eabi-gcc
    install_stm32_cross_compiler x86_64
fi

print_status_msg "Setting up PlatformIO device access"
curl -fsSL https://raw.githubusercontent.com/platformio/platformio-core/develop/platformio/assets/system/99-platformio-udev.rules \
    -o /tmp/tbots_download_cache/99-platformio-udev.rules
sudo install -m 644 /tmp/tbots_download_cache/99-platformio-udev.rules \
    /etc/udev/rules.d/99-platformio-udev.rules
sudo udevadm control --reload-rules
sudo udevadm trigger
if ! id -nG | tr ' ' '\n' | grep -qx uucp; then
    sudo usermod -aG uucp "$(id -un)"
fi
if [[ ! -e /usr/local/bin/platformio || -L /usr/local/bin/platformio ]]; then
    sudo ln -sfnT /opt/tbotspython/bin/platformio /usr/local/bin/platformio
fi

/opt/tbotspython/bin/ansible-galaxy collection install ansible.posix
print_status_msg "CachyOS setup complete. Log out and back in before using USB devices."
