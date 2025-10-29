#!/bin/bash

# Check if proteins file is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <proteins_file>"
    echo "Example: $0 proteins.txt"
    exit 1
fi

PROTEINS_FILE="$1"

# Check if file exists
if [ ! -f "$PROTEINS_FILE" ]; then
    echo "Error: File '$PROTEINS_FILE' not found"
    exit 1
fi

while IFS= read -r PROT || [ -n "$PROT" ]; do
    MSA_JOBID=$(sbatch --parsable --time=00:30:00 sbatch_compute_msa.sh "$PROT")
    sbatch --time=00:30:00 --dependency=afterok:${MSA_JOBID} sbatch_openfold_test.sh "$PROT" 0
done < "$PROTEINS_FILE"
