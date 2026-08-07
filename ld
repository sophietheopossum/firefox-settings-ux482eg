#!/bin/bash
# ld → Wild (system-wide performance default), with two compatibility shims:
#
# 1. Free Pascal: FPC hardcodes the BFD-only "-b elf64-x86-64" input-format
#    flag, which Wild rejects outright ("unrecognized option(s): -b"), exactly
#    as LLD did before it. FPC's inputs are ordinary ELF objects, so the flag
#    is a no-op — drop exactly that flag/value pair (both spellings) and pass
#    everything else, including "-b binary", through.
#
# 2. GCC LTO: inherited from the LLD era and probably now dead code. LLD could
#    not load GCC's LTO plugin, so GIMPLE-only LTO objects linked as
#    "undefined symbol: ..." (this broke every makepkg lto build, e.g.
#    qbittorrent-enhanced's CMake configure). GCC gives the linker no
#    distinguishing flag — LTO-ness lives in the inputs — so sniff the
#    command-line objects/archives (and @response files) for a ".gnu.lto_"
#    section and route exactly those links to mold.
#
#    Wild does NOT share that limitation: it accepts GCC's
#    "-plugin .../liblto_plugin.so" and links GIMPLE-only objects into a
#    working binary (verified 7/8/2026 on gcc 16.1.1). The sniff is kept as a
#    safety net rather than deleted, because the failure it prevents is a wall
#    of undefined symbols deep inside a package build, and mold is in Wild's
#    speed class so the fallback costs nothing when taken. It is not free when
#    NOT taken, though — it greps every input on every link — so if Wild proves
#    itself on real LTO packages, deleting shim 2 is the tidy-up.
backend=/usr/bin/ld.wild

has_gimple() {
    # Section names (".gnu.lto_...") appear verbatim in the ELF shstrtab.
    grep -aqsm1 -e '\.gnu\.lto_' -- "$1"
}

args=()
pending_format=""
for a in "$@"; do
    if [[ -n $pending_format ]]; then
        pending_format=""
        [[ $a == elf64-x86-64 ]] && continue
        args+=("-b" "$a")
        continue
    fi
    case $a in
        -b|--format) pending_format=1; continue ;;
        --format=elf64-x86-64|-belf64-x86-64) continue ;;
    esac
    args+=("$a")
    [[ $backend == /usr/bin/ld.mold ]] && continue
    case $a in
        @?*)
            # Response file: one input path per line (possibly quoted).
            while IFS= read -r line; do
                line=${line#\"}; line=${line%\"}
                [[ -f $line ]] && has_gimple "$line" && backend=/usr/bin/ld.mold && break
            done < "${a#@}"
            ;;
        -*) ;;
        *)
            [[ -f $a ]] && has_gimple "$a" && backend=/usr/bin/ld.mold
            ;;
    esac
done
exec "$backend" "${args[@]}"