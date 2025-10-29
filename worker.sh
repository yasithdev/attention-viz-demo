#!/bin/bash

# Worker: dequeue task, run script, enqueue result, handle timeout

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/work_queue.sh"

CURRENT_TASK="" CURRENT_CLAIMED_FILE=""

on_timeout() {
    [ -n "$CURRENT_CLAIMED_FILE" ] && reenqueue "$1" "$CURRENT_CLAIMED_FILE"
    exit 0
}

trap 'on_timeout "$INPUT_QUEUE_DIR"' SIGUSR1

[ $# -lt 2 ] && echo "Usage: $0 <input_queue> [output_queue] <task_script>" && exit 1

INPUT_QUEUE_DIR="$1" OUTPUT_QUEUE_DIR="$2" TASK_SCRIPT="$3"

[ -n "$OUTPUT_QUEUE_DIR" ] && mkdir -p "$OUTPUT_QUEUE_DIR"

while ! is_queue_empty "$INPUT_QUEUE_DIR"; do
    CURRENT_TASK=$(dequeue "$INPUT_QUEUE_DIR") || exit 0
    CURRENT_CLAIMED_FILE="$INPUT_QUEUE_DIR/${CURRENT_TASK}.claimed.$$"
    
    if "$TASK_SCRIPT" "$CURRENT_TASK"; then
        [ -n "$OUTPUT_QUEUE_DIR" ] && enqueue "$OUTPUT_QUEUE_DIR" "$CURRENT_TASK"
        cleanup_claimed "$CURRENT_CLAIMED_FILE"
    else
        reenqueue "$INPUT_QUEUE_DIR" "$CURRENT_CLAIMED_FILE"
    fi
    
    CURRENT_TASK="" CURRENT_CLAIMED_FILE=""
done
