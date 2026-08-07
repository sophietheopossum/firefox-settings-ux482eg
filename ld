#!/bin/bash
# ld → Wild (system-wide performance default), with two compatibility shims,
# both of them for Free Pascal:
#
# 1. FPC hardcodes the BFD-only "-b elf64-x86-64" input-format flag, which Wild
#    rejects outright ("unrecognized option(s): -b"), exactly as LLD did before
#    it. FPC's inputs are ordinary ELF objects, so the flag is a no-op — drop
#    exactly that flag/value pair (both spellings) and pass everything else,
#    including "-b binary", through.
#
# 2. FPC also hands the linker a generated link<pid>.res GNU linker script, and
#    Wild's script parser dies on its very first line ("Failed to parse linker
#    script: parse error at line 1, column 11 | SEARCH_DIR("/lib64/")"). LLD
#    parses it happily. So any input that looks like a linker script routes the
#    whole link back to LLD.
#
# There was a third shim, from the LLD era, routing GCC-LTO links to mold: LLD
# cannot load GCC's LTO plugin, so GIMPLE-only objects linked as "undefined
# symbol: ..." and it broke every makepkg lto build (e.g. qbittorrent-enhanced,
# which surfaced as a bogus CMake configure error). Removed 7/8/2026 — Wild
# accepts "-plugin .../liblto_plugin.so" and links GIMPLE-only objects into a
# working binary, so the sniff was dead code that read every input on every
# link looking for ".gnu.lto_". If GCC-LTO links ever start failing with
# undefined symbols again, that is the shim to resurrect.
backend=/usr/bin/ld.wild

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
    # Value of an option that takes a separate path: passed through verbatim
    # and never treated as an input to inspect. An option's value is not an
    # input file, and forgetting that cost weeks here — GCC is built
    # --enable-plugin, so it passes "-plugin .../liblto_plugin.so" on EVERY
    # link, and the old GCC-LTO sniff read that plugin binary, which naturally
    # contains the ".gnu.lto_" string it was hunting for. Every gcc link
    # therefore matched and was silently diverted. That sniff is gone, but keep
    # this list: it is correct on its own terms and stops the next such bug.
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
    # Once something has routed us off the default there is nothing left to
    # look for, so stop inspecting inputs.
    [[ $backend != /usr/bin/ld.wild ]] && continue
    case $a in
        @?*)
            # Response file: one input path per line (possibly quoted). Scanned
            # for the same linker-script case as a direct input, since a build
            # system long enough to need @files can still name a script inside.
            [[ -f ${a#@} ]] || continue
            while IFS= read -r line; do
                line=${line#\"}; line=${line%\"}
                [[ -f $line ]] && is_ld_script "$line" && backend=/usr/bin/ld.lld && break
            done < "${a#@}"
            ;;
        -*) ;;
        *)
            [[ -f $a ]] && is_ld_script "$a" && backend=/usr/bin/ld.lld
            ;;
    esac
done
exec "$backend" "${args[@]}"