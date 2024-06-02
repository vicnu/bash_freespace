#!/bin/bash
timeout=48
is_compressed() {
    case "$1" in
        *.zip|*.gz|*.bz2|*.xz) return 0 ;;
        *) return 1 ;;
    esac
}
process_file() {
    local file="$1"
    if [[ -d "$file" ]]; then
        if [[ "$recursive" == true ]]; then
            find "$file" -type f -exec "$0" -r -t "$timeout" {} \;
        else
            for subfile in "$file"/*; do
                [[ -f "$subfile" ]] && process_file "$subfile"
            done
        fi
    elif [[ "$file" == fc-* ]]; then
        if [[ $(find "$file" -mmin +$(($timeout * 60))) ]]; then
            rm -f "$file"
        fi
    elif is_compressed "$file"; then
        mv "$file" "fc-${file##*/}"
        touch "fc-${file##*/}"
    else
        zip "fc-${file##*/}.zip" "$file" && rm -f "$file"
    fi
}

while getopts ":rt:" opt; do
    case $opt in
        r) recursive=true ;;
        t) timeout="$OPTARG" ;;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
        :) echo "Option -$OPTARG requires an argument." >&2; exit 1 ;;
    esac
done
shift $((OPTIND -1))
if [ $# -eq 0 ]; then
    echo "Usage: freespace [-r] [-t ###] file [file...]"
    exit 1
fi
for file in "$@"; do
    process_file "$file"
done
find . -type f -name 'fc-*' -mmin +$(($timeout * 60)) -exec rm -f {} \;
