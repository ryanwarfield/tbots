- Added a CachyOS x86_64 setup script using pacman and AUR packages.
- Kept the Python 3.12 environment and downloaded tools under `/opt/tbotspython` without deleting existing data.
- Installed PyQt6 and PlatformIO into the Python 3.12 environment.
- Used Arch's Java 21 and `uucp` device access.
- Reused the Linux game controller, AutoReferee, and firmware tool downloads.
- Added a rerunnable GCC 10 link for master's Ubuntu library path.
The port keeps the same layout that master expects, while replacing Ubuntu’s installation steps with CachyOS ones.
[setup_software_cachyos.sh](/home/ryan/hacking/tbots/environment_setup/setup_software_cachyos.sh) installs ordinary packages with pacman and GCC 10 and Python 3.12 from the AUR. Python 3.12 gets its own /opt/tbotspython environment because your system Python is 3.14. PyQt6 and PlatformIO go into that environment, so they use the right Python version. The script also reuses the existing helpers for the game controller, AutoReferee, and firmware toolchains. For USB access, it uses Arch’s uucp group and reloads udev rules.
[cachyos_relink_gcc.sh](/home/ryan/hacking/tbots/environment_setup/cachyos_relink_gcc.sh) handles the deliberate bit of jank: AUR’s GCC 10 libraries live in an Arch-style directory, while master looks in an Ubuntu-style one. It finds GCC 10’s actual directory and creates a link at the path master expects. It refuses to replace a real directory there. You can rerun this small script if the link breaks.
The installer avoids deleting /opt/tbotspython, which the Ubuntu script does, so rerunning it preserves existing data. The exact changes are also listed in [cachyos_changes.md](/home/ryan/hacking/tbots/environment_setup/cachyos_changes.md).
Everything is on cachyos-setup. Syntax checks passed, but I haven’t run the installer or a Bazel build, so the AUR builds and GCC link still need a real-world check.


22:07