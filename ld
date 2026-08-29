#!/bin/bash
# ld → Wild (system-wide performance default), with three compatibility shims,
# the first two for Free Pascal:
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
# 3. (32-bit) Wild is x86-64 only: a 32-bit link fails with "-m elf_i386 is not yet
#    supported", and because GCC asks the linker to identify itself by running
#    "gcc -m32 -Wl,--version", the failure surfaces upstream of any actual link
#    as meson's "Unable to detect linker for compiler `gcc -m32 ...`" — which
#    names neither Wild nor this shim. So an elf_i386 emulation routes away from
#    Wild: to LLD, which is fast and handles i386 fine, EXCEPT when the link
#    carries GCC LTO objects — LLD cannot load GCC's LTO plugin and mangles them
#    silently. The GIMPLE sniff after the loop sends exactly those links to BFD.
#
# There was a fourth shim, from the LLD era, routing GCC-LTO links to mold: LLD
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
pending_emul=""
is32=""
inputs=()
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
    # Output emulation, latched because GCC passes it as "-m elf_i386" rather
    # than joined. This only marks the link as 32-bit; which 32-bit backend it
    # gets is decided after the whole command line is known, below.
    if [[ -n $pending_emul ]]; then
        pending_emul=""
        [[ $a == elf_i386 ]] && { is32=1; backend=/usr/bin/ld.lld; }
        args+=("$a")
        continue
    fi
    case $a in
        -b|--format) pending_format=1; continue ;;
        --format=elf64-x86-64|-belf64-x86-64) continue ;;
        -plugin|-o|--output|-dynamic-linker) pending_opaque=1 ;;
        -m) pending_emul=1 ;;
        -melf_i386) is32=1; backend=/usr/bin/ld.lld ;;
    esac
    args+=("$a")
    # Input paths are collected even once something has routed us off the
    # default, because a 32-bit link chooses its backend after the whole command
    # line is known and needs the full list. Only the EXPENSIVE part -- reading
    # each file for the linker-script sniff -- is still skipped once diverted.
    case $a in
        @?*)
            # Response file: one input path per line (possibly quoted). Scanned
            # for the same linker-script case as a direct input, since a build
            # system long enough to need @files can still name a script inside.
            [[ -f ${a#@} ]] || continue
            while IFS= read -r line; do
                line=${line#\"}; line=${line%\"}
                [[ -f $line ]] || continue
                inputs+=("$line")
                [[ $backend == /usr/bin/ld.wild ]] && is_ld_script "$line" \
                    && backend=/usr/bin/ld.lld
            done < "${a#@}"
            ;;
        -*) ;;
        *)
            [[ -f $a ]] || continue
            inputs+=("$a")
            [[ $backend == /usr/bin/ld.wild ]] && is_ld_script "$a" \
                && backend=/usr/bin/ld.lld
            ;;
    esac
done

# 32-bit backend choice: LLD normally, BFD when the link contains GCC LTO.
#
# LLD cannot load GCC's LTO plugin, and it does not fail on a GIMPLE object --
# it copies it into the output unprocessed. A shared library needs no resolved
# symbols, so the link SUCCEEDS and silently yields a hollow .so: lib32-orc's
# liborc exported 1 symbol where BFD exported 931, and `nm` on it said "plugin
# needed to handle lto object". The breakage surfaced only at the next
# executable, as "undefined symbol: main" referenced by Scrt1.o -- naming
# neither LTO nor the linker. So GIMPLE inputs go to BFD, which loads the plugin.
#
# Two things keep this cheap and correct where the old GCC-LTO-to-mold sniff was
# neither. It runs ONLY on 32-bit links, so ordinary x86-64 links pay nothing.
# And it reads only collected INPUTS, never an option's value -- reading
# "-plugin .../liblto_plugin.so" as an input is exactly what made the old sniff
# match every gcc link, since the plugin binary contains the string it hunted.
if [[ -n $is32 && ${#inputs[@]} -gt 0 ]] \
   && grep -qsaF -e '.gnu.lto_' -- "${inputs[@]}"; then
    backend=/usr/bin/ld.bfd
fi

exec "$backend" "${args[@]}"
