# Shared helper for bin/run_dev and bin/run_tests.
#
# fades caches a virtualenv by its `-d` dependency spec + interpreter only;
# `--pip-options` (our `-e .` / `-e .[dev]`) are applied *once*, when that venv
# is first created, and are silently ignored on every later cache hit — fades'
# own source marks this explicitly ("pip_options mustn't store"). So editing
# pyproject.toml (adding a dependency, adding an extra) does nothing on the
# next run: fades finds the old venv still matches on `-d` alone and reuses it
# as-is, never re-running pip. `FADES_REBUILD=1` used to paper over this with
# `--force-reinstall`, but that's a pip option too, so it never even ran.
#
# _fades_ensure_fresh_venv hashes pyproject.toml and remembers the hash in a
# marker file; when it changes (or FADES_REBUILD=1 is set), it deletes the
# matching cached venv via `fades --rm` *before* the real fades invocation, so
# that invocation creates a fresh one and --pip-options actually applies.
_fades_ensure_fresh_venv() {
    local marker_name="$1"
    shift
    local dep_args=("$@")
    local marker_file="$repo_root/.fades-hash-${marker_name}"
    local current_hash
    current_hash="$(sha256sum "$repo_root/pyproject.toml" | cut -d' ' -f1)"

    if [[ "${FADES_REBUILD:-}" == "1" || ! -f "$marker_file" ]] \
        || [[ "$(cat "$marker_file")" != "$current_hash" ]]; then
        local venv_dir uuid
        venv_dir="$(fades "${dep_args[@]}" --get-venv-dir 2>/dev/null || true)"
        if [[ -n "$venv_dir" ]]; then
            uuid="$(basename "$venv_dir")"
            fades --rm "$uuid" >/dev/null 2>&1 || true
        fi
    fi
    echo "$current_hash" > "$marker_file"
}
