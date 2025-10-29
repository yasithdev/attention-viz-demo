#!/bin/bash

# Orchestrator: init queues, launch workers, wait for completion

[ $# -eq 0 ] && echo "Usage: $0 <proteins_file>" && exit 1
[ ! -f "$1" ] && echo "Error: File '$1' not found" && exit 1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/work_queue.sh"

# code to launch workers and wait for completion
JOB_ID="job_$(date +%s)_$$"
MSA_QUEUE_DIR="msa_queue_${JOB_ID}"
OPENFOLD_QUEUE_DIR="openfold_queue_${JOB_ID}"

init_queue "$MSA_QUEUE_DIR" "$1"
mkdir -p "$OPENFOLD_QUEUE_DIR"

TOTAL_PROTEINS=$(wc -l < "$1")
MSA_JOB_IDS=() OPENFOLD_JOB_IDS=()

# Launch MSA workers
for i in $(seq 1 $TOTAL_PROTEINS); do
    MSA_JOB_IDS+=($(sbatch --parsable --time=00:30:00 --signal=B:USR1@60 \
        --job-name=msa_worker --partition=cpu --account=bekh-delta-cpu \
        --cpus-per-task=4 --mem=128G \
        "$SCRIPT_DIR/worker.sh" "$MSA_QUEUE_DIR" "$OPENFOLD_QUEUE_DIR" "$SCRIPT_DIR/task_msa.sh"))
done

# Launch OpenFold workers dynamically as MSA tasks complete
while [ ${#OPENFOLD_JOB_IDS[@]} -lt $TOTAL_PROTEINS ]; do
    # Count completed MSA tasks (files in OpenFold queue)
    COMPLETED_MSA=$(ls "$OPENFOLD_QUEUE_DIR" 2>/dev/null | wc -l)
    
    # Launch OpenFold workers for newly completed MSA tasks
    while [ ${#OPENFOLD_JOB_IDS[@]} -lt $COMPLETED_MSA ]; do
        OPENFOLD_JOB_IDS+=($(sbatch --parsable --time=00:30:00 --signal=B:USR1@60 \
            --job-name=openfold_worker --partition=gpuA100x4 --account=bbve-delta-gpu \
            --gres=gpu:1 --mem=64G --ntasks=1 --cpus-per-task=8 \
            "$SCRIPT_DIR/worker.sh" "$OPENFOLD_QUEUE_DIR" "" "$SCRIPT_DIR/task_openfold.sh"))
    done
    
    # Check if all MSA workers are done
    RUNNING_MSA=$(squeue -j "${MSA_JOB_IDS[*]}" -h 2>/dev/null | wc -l)
    [ $RUNNING_MSA -eq 0 ] && break
    
    sleep 5
done

# Wait for completion
ALL_JOB_IDS=("${MSA_JOB_IDS[@]}" "${OPENFOLD_JOB_IDS[@]}")
while [ $(squeue -j "${ALL_JOB_IDS[*]}" -h 2>/dev/null | wc -l) -gt 0 ]; do
    sleep 30
done

rm -rf "$MSA_QUEUE_DIR" "$OPENFOLD_QUEUE_DIR"
