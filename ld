#!/bin/bash
# ld → LLD (system-wide performance default), with two compatibility shims:
#
# 1. Free Pascal: FPC hardcodes the BFD-only "-b elf64-x86-64" input-format
#    flag, which LLD rejects outright. FPC's inputs are ordinary ELF objects,
#    so the flag is a no-op — drop exactly that flag/value pair (both
#    spellings) and pass everything else, including "-b binary", through.
#
# 2. GCC LTO: LLD cannot load GCC's LTO plugin, so GIMPLE-only LTO objects
#    link as "undefined symbol: ..." (this broke every makepkg lto build,
#    e.g. qbittorrent-enhanced's CMake configure). GCC gives the linker no
#    distinguishing flag — LTO-ness lives in the inputs — so sniff the
#    command-line objects/archives (and @response files) for a ".gnu.lto_"
#    section and route exactly those links to mold, which supports GCC's
#    plugin and is in LLD's speed class. Clang/Rust LTO uses LLVM bitcode,
#    which LLD handles natively, so everything else stays on LLD.
backend=/usr/bin/ld.lld

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