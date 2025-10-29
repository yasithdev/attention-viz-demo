#!/bin/bash

# Work Queue: directory with files as tasks, atomic mv for claiming
init_queue() {
    mkdir -p "$1"
    while IFS= read -r item || [ -n "$item" ]; do
        [ -n "$item" ] && touch "$1/$item"
    done < "$2"
}

dequeue() {
    for file in "$1"/*; do
        [ -f "$file" ] && [[ ! "$file" =~ \.claimed\.[0-9]+$ ]] && \
        mv "$file" "${file}.claimed.$$" 2>/dev/null && \
        echo "$(basename "$file")" && return 0
    done
    return 1
}

enqueue() { touch "$1/$2"; }

is_queue_empty() {
    for file in "$1"/*; do
        [ -f "$file" ] && [[ ! "$file" =~ \.claimed\.[0-9]+$ ]] && return 1
    done
    return 0
}

reenqueue() {
    [ -f "$2" ] && mv "$2" "${2%.claimed.*}"
}

cleanup_claimed() { rm -f "$1"; }
