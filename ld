#!/bin/bash
# ld → mold (system-wide performance default), with two compatibility shims,
# both for Free Pascal:
#
# 1. FPC hardcodes the BFD-only "-b elf64-x86-64" input-format flag, which mold
#    rejects outright, exactly as Wild and LLD did before it. FPC's inputs are
#    ordinary ELF objects, so the flag is a no-op — drop exactly that
#    flag/value pair (both spellings) and pass everything else, including
#    "-b binary", through.
#
# 2. FPC also hands the linker a generated link<pid>.res GNU linker script.
#    mold 3.0 stops on its first line with "unknown linker script token" for
#    SEARCH_DIR("/lib64/"). LLD parses it happily. So any input that looks like
#    a linker script routes the whole link back to LLD.
#
# Returning to mold removed the Wild-era 32-bit routing: mold handles
# elf_i386 and loads GCC's LTO plugin, including for 32-bit LTO outputs.
backend=/usr/bin/ld.mold

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
        -plugin|-o|--output|-dynamic-linker|-m) pending_opaque=1 ;;
    esac
    args+=("$a")
    # The linker-script sniff reads inputs only while still on mold.
    case $a in
        @?*)
            # Response file: one input path per line (possibly quoted). Scanned
            # for the same linker-script case as a direct input, since a build
            # system long enough to need @files can still name a script inside.
            [[ -f ${a#@} ]] || continue
            while IFS= read -r line; do
                line=${line#\"}; line=${line%\"}
                [[ -f $line ]] || continue
                [[ $backend == /usr/bin/ld.mold ]] && is_ld_script "$line" \
                    && backend=/usr/bin/ld.lld
            done < "${a#@}"
            ;;
        -*) ;;
        *)
            [[ -f $a ]] || continue
            [[ $backend == /usr/bin/ld.mold ]] && is_ld_script "$a" \
                && backend=/usr/bin/ld.lld
            ;;
    esac
done

exec "$backend" "${args[@]}"
