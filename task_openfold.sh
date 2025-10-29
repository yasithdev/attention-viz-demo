#!/bin/bash

# OpenFold computation task script
# Takes protein ID as first argument and runs OpenFold computation

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Usage: $0 <protein_id> [triangle_residue_idx]"
    exit 1
fi

PROT="$1"
TRI_RESIDUE_IDX="${2:-0}"  # Default to 0 if not provided

echo "Starting OpenFold computation for $PROT at $(date)"
START_TIME=$(date +%s)

# Paths from original sbatch_openfold_test.sh
BASE_DATA_DIR=/ime/hdd/rhaas/SUP-5301/database
BASE_FASTA_DIR=/projects/cqj/thayes/cameo_msas/fasta_dir
ALIGNMENT_DIR=/projects/cqj/thayes/cameo_msas/alignments
BASE_ATTN_DIR=/work/hdd/bekh/thayes/test_attn

# Setup log paths
LOG_DIR="$BASE_ATTN_DIR/logs"
OUT_FILE="${LOG_DIR}/inference_attn_${PROT}.out"
ERR_FILE="${LOG_DIR}/inference_attn_${PROT}.err"
echo "Logging to: $OUT_FILE (stdout) and $ERR_FILE (stderr)"

# Redirect output to log files
exec > >(tee -a "$OUT_FILE") 2> >(tee -a "$ERR_FILE" >&2)

# Local paths for saving results
ATTN_MAP_DIR="$BASE_ATTN_DIR/attention_files_${PROT}_demo_tri_${TRI_RESIDUE_IDX}"
OUTPUT_DIR="$BASE_ATTN_DIR/my_outputs_align_${PROT}_demo_tri_${TRI_RESIDUE_IDX}"
TEMPLATE_MMCIF_DIR="$BASE_DATA_DIR/pdb_mmcif/mmcif_files"
FASTA_DIR="$BASE_FASTA_DIR/${PROT}.fasta"

# Ensure output directory exists
mkdir -p $LOG_DIR $ATTN_MAP_DIR $OUTPUT_DIR

echo "Running OpenFold inference for $PROT"

# Run OpenFold inference
python3 run_pretrained_openfold.py \
    ${FASTA_DIR} \
    ${BASE_DATA_DIR}/pdb_mmcif/mmcif_files \
    --use_precomputed_alignments ${ALIGNMENT_DIR} \
    --output_dir ${OUTPUT_DIR} \
    --config_preset model_1_ptm \
    --uniref90_database_path ${BASE_DATA_DIR}/uniref90/uniref90.fasta \
    --mgnify_database_path ${BASE_DATA_DIR}/mgnify/mgy_clusters_2022_05.fa \
    --pdb70_database_path ${BASE_DATA_DIR}/pdb70/pdb70 \
    --uniclust30_database_path ${BASE_DATA_DIR}/uniclust30/uniclust30_2018_08 \
    --bfd_database_path ${BASE_DATA_DIR}/bfd/bfd_metaclust_clu_complete_id30_c90_final_seq.sorted_opt \
    --save_outputs \
    --model_device "cuda:0" \
    --attn_map_dir ${ATTN_MAP_DIR} \
    --num_recycles_save 1 \
    --triangle_residue_idx ${TRI_RESIDUE_IDX} \
    --enable_chunking \
    --demo_attn \
    --skip_relaxation

EXIT_CODE=$?

END_TIME=$(date +%s)
RUNTIME=$((END_TIME - START_TIME))

if [ $EXIT_CODE -eq 0 ]; then
    echo "OpenFold computation completed successfully for $PROT"
    echo "Total runtime: $RUNTIME seconds"
    printf "Formatted: %02d:%02d:%02d\n" $((RUNTIME/3600)) $((RUNTIME%3600/60)) $((RUNTIME%60))
else
    echo "OpenFold computation failed for $PROT with exit code $EXIT_CODE"
    echo "Total runtime: $RUNTIME seconds"
fi

exit $EXIT_CODE
