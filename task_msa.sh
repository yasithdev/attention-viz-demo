#!/bin/bash

# MSA computation task script
# Takes protein ID as first argument and runs MSA computation

if [ $# -ne 1 ]; then
    echo "Usage: $0 <protein_id>"
    exit 1
fi

PROT="$1"

echo "Starting MSA computation for $PROT at $(date)"
START_TIME=$(date +%s)

# Paths from original sbatch_compute_msa.sh
BASE_DATA_DIR=/ime/hdd/rhaas/SUP-5301/database
BASE_FASTA_DIR=/projects/cqj/thayes/cameo_msas/fasta_dir
ALIGNMENT_DIR=/projects/cqj/thayes/cameo_msas/alignments

# Path for the unaligned sequences
FASTA_PATH="$BASE_FASTA_DIR/$PROT"

# Ensure output directory exists
OUTDIR="$ALIGNMENT_DIR/$PROT.fasta"
mkdir -p $OUTDIR

echo "Running alignment on $FASTA_PATH → $OUTDIR"

# Run the MSA computation
python run_precompute_alignments.py "$FASTA_PATH" "$OUTDIR" \
    --uniref90_database_path "$BASE_DATA_DIR/uniref90/uniref90.fasta" \
    --mgnify_database_path "$BASE_DATA_DIR/mgnify/mgy_clusters_2022_05.fa" \
    --pdb70_database_path "$BASE_DATA_DIR/pdb70/pdb70" \
    --uniclust30_database_path "$BASE_DATA_DIR/uniclust30/uniclust30_2018_08" \
    --bfd_database_path "$BASE_DATA_DIR/bfd/bfd_metaclust_clu_complete_id30_c90_final_seq.sorted_opt" \
    --cpus 4

EXIT_CODE=$?

END_TIME=$(date +%s)
RUNTIME=$((END_TIME - START_TIME))

if [ $EXIT_CODE -eq 0 ]; then
    echo "MSA computation completed successfully for $PROT"
    echo "Total runtime: $RUNTIME seconds"
    printf "Formatted: %02d:%02d:%02d\n" $((RUNTIME/3600)) $((RUNTIME%3600/60)) $((RUNTIME%60))
else
    echo "MSA computation failed for $PROT with exit code $EXIT_CODE"
    echo "Total runtime: $RUNTIME seconds"
fi

exit $EXIT_CODE
