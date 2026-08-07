#!/bin/bash
# ld → Wild (system-wide performance default), with three compatibility shims:
#
# 1. Free Pascal: FPC hardcodes the BFD-only "-b elf64-x86-64" input-format
#    flag, which Wild rejects outright ("unrecognized option(s): -b"), exactly
#    as LLD did before it. FPC's inputs are ordinary ELF objects, so the flag
#    is a no-op — drop exactly that flag/value pair (both spellings) and pass
#    everything else, including "-b binary", through.
#
# 1b. …and that is not enough for FPC on Wild. FPC also hands the linker a
#    generated link<pid>.res GNU linker script, and Wild's script parser dies
#    on its very first line ("Failed to parse linker script: parse error at
#    line 1, column 11 | SEARCH_DIR("/lib64/")"). LLD parses it happily, which
#    is why Pascal builds worked before the switch — FPC drives ld directly,
#    so it never hit the -plugin bug described in shim 2 and was genuinely the
#    only thing still reaching LLD. Any input that looks like a linker script
#    therefore routes the whole link back to LLD.
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

is_ld_script() {
    # GNU linker scripts are plain text, so -I (skip binaries) makes this cheap
    # on the object files and archives that make up almost every link, and it
    # cannot false-positive on an ELF that happens to contain the keyword.
    grep -Iqsm1 -e 'SEARCH_DIR(' -e 'INPUT(' -e 'GROUP(' -- "$1"
}

args=()
pending_format=""
pending_opaque=""
for a in "$@"; do
    if [[ -n $pending_format ]]; then
        pending_format=""
        [[ $a == elf64-x86-64 ]] && continue
        args+=("-b" "$a")
        continue
    fi
    # Value of an option that takes a separate path, passed through verbatim
    # and never sniffed. This matters: GCC is built --enable-plugin, so it
    # passes "-plugin .../liblto_plugin.so" on EVERY link, LTO or not — and
    # the plugin binary itself contains the ".gnu.lto_" string it exists to
    # look for. Sniffing it made has_gimple hit unconditionally and quietly
    # sent every gcc link to the fallback. "-o" is here for the same class of
    # reason: relinking over a previous LTO output must not re-trigger it.
    if [[ -n $pending_opaque ]]; then
        pending_opaque=""
        args+=("$a")
        continue
    fi
    case $a in
        -b|--format) pending_format=1; continue ;;
        --format=elf64-x86-64|-belf64-x86-64) continue ;;
        -plugin|-o|--output|-dynamic-linker) pending_opaque=1 ;;
    esac
    args+=("$a")
    # Once anything has routed us off the default, stop sniffing.
    [[ $backend != /usr/bin/ld.wild ]] && continue
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
            [[ -f $a ]] || continue
            if is_ld_script "$a"; then
                backend=/usr/bin/ld.lld
            elif has_gimple "$a"; then
                backend=/usr/bin/ld.mold
            fi
            ;;
    esac
done
exec "$backend" "${args[@]}"