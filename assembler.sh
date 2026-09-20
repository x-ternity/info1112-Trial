#!/usr/bin/env bash
if [ $# -eq 0 ]; then
    echo "usage: no argument is provided"
    exit 1
fi

if [ $# -gt 1 ]; then
    echo "usage: more than one arguments are provided"
    exit 1
fi

if [ -d "$1" ]; then
    echo "usage: input is not a file or it does not exist"
    exit 1
fi

if [[ "$1" != *.vsc ]]; then
    echo "usage: input does not have the extension .vsc"
    exit 1
fi


if [ ! -f "$1" ]; then
    echo "usage: input is not a file or it does not exist"
    exit 1
fi

if [ ! -s "$1" ]; then
    echo "usage: the file is empty - no .bin file is produced"
    exit 1
fi

# ---------- split the .vsc file into its three parts ----------
n_values=$(head -n 1 "$1")
statics=$(tail -n +2 "$1" | head -n "$n_values")
instructions=$(tail -n +$((n_values + 2)) "$1")

# ---------- collect every byte into a list ----------
bytes=()

if [ "$n_values" -gt 0 ]; then
    while read -r value; do
        bytes+=("$value")
    done <<< "$statics"
fi

kind="QUIT"

while IFS=, read -r name reg addr; do
    if [ -z "$name" ]; then
        continue
    fi

    case "$name" in
        LOAD)  opcode=1 ;;
        STORE) opcode=2 ;;
        ADD)   opcode=3 ;;
        SUB)   opcode=4 ;;
        QUIT)  opcode=8 ;;
        PRINT) opcode=9 ;;
    esac

    if [ "$name" = "ADD" ] || [ "$name" = "SUB" ]; then
        kind="ADD/SUB"
    fi

    bytes+=( $(( (opcode << 2) + reg )) )
    bytes+=( "$addr" )
done <<< "$instructions"

# ---------- say what kind of program it is ----------
if [ "$kind" = "QUIT" ]; then
    echo "It is a QUIT program"
else
    echo "It is an ADD/SUB program"
fi

# ---------- write the .bin file and print it ----------
outfile="${1%.vsc}.bin"
: > "$outfile"

echo "The content of the .bin file is"
for b in "${bytes[@]}"; do
    printf "%02x\n" "$b"
    printf "\x$(printf %02x "$b")" >> "$outfile"
done

exit 0
