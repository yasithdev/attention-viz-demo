#!/bin/bash
#SBATCH --job-name=openfold_test
#SBATCH --partition=gpuA100x4
#SBATCH --account=bbol-delta-gpu
#SBATCH --gres=gpu:1
#SBATCH --mem=64G
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --requeue
#SBATCH --signal=B:USR1@60  # warn 60 sec before timeout

on_timeout() {
  echo "Requeuing job"
  curr_min=$(scontrol show job $SLURM_JOB_ID | awk -F= '/TimeLimit=/ {split($2,a,":"); print a[1]*60 + a[2]}')
  new_min=$(( curr_min * 2 ))
  echo "Requeuing job with walltime ${curr_min} -> ${new_min} minutes"
  scontrol update JobId=${SLURM_JOB_ID} TimeLimit=${new_min}
  scontrol requeue ${SLURM_JOB_ID}
  exit 0
}
trap 'on_timeout' SIGUSR1

echo "Starting job at $(date)"

# Get script directory and run the task script
if [[ -n "$SLURM_SUBMIT_DIR" ]]; then
    SCRIPT_DIR="$SLURM_SUBMIT_DIR"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
"$SCRIPT_DIR/task_openfold.sh" "$1" "$2"
