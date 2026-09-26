#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [[ -r /opt/tbotspython/cachyos_bazel_root ]] &&
    [[ "$repo_root" == "$(< /opt/tbotspython/cachyos_bazel_root)" ]]; then
    compilation_mode=fastbuild
    previous_arg=
    for arg in "$@"; do
        if [[ "$previous_arg" == -c || "$previous_arg" == --compilation_mode ]]; then
            compilation_mode=$arg
        fi
        case "$arg" in
            -c=*) compilation_mode=${arg#-c=} ;;
            --compilation_mode=*) compilation_mode=${arg#--compilation_mode=} ;;
        esac
        previous_arg=$arg
    done

    bazel_args=()
    config_added=false
    for arg in "$@"; do
        bazel_args+=("$arg")
        if [[ "$config_added" == false && "$compilation_mode" != opt ]] &&
            [[ "$arg" == build || "$arg" == test || "$arg" == run || "$arg" == coverage ]]; then
            bazel_args+=(--config=cachyos_noopt)
            config_added=true
        fi
    done
    exec /usr/bin/bazel --bazelrc=/opt/tbotspython/cachyos.bazelrc "${bazel_args[@]}"
fi

exec /usr/bin/bazel "$@"
