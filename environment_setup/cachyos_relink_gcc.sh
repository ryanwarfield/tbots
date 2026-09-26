#!/usr/bin/env bash
set -euo pipefail

if [[ ! -x /usr/bin/gcc-10 ]]; then
    echo "Install the AUR gcc10 package first." >&2
    exit 1
fi

gcc_lib_dir=$(dirname -- "$(/usr/bin/gcc-10 -print-libgcc-file-name)")
if [[ ! -f "$gcc_lib_dir/libstdc++.a" || ! -e "$gcc_lib_dir/libstdc++.so" ]]; then
    echo "GCC 10 C++ libraries are missing from $gcc_lib_dir." >&2
    exit 1
fi

compat_dir=/usr/lib/gcc/x86_64-linux-gnu/10
if [[ -e "$compat_dir" && ! -L "$compat_dir" ]]; then
    echo "Refusing to replace the existing directory $compat_dir." >&2
    exit 1
fi

sudo install -d -- "$(dirname -- "$compat_dir")"
sudo ln -sfnT -- "$gcc_lib_dir" "$compat_dir"
echo "Linked $compat_dir to $gcc_lib_dir"
