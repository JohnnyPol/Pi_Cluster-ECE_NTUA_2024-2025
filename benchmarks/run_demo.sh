#!/bin/bash

TARGET_DIR="/mnt/hpc_shared/demo"
LOG_FILE="$TARGET_DIR/job_submissions.log"

(
  cd "$TARGET_DIR" || { echo "Error: Directory not found $TARGET_DIR"; exit 1; }

  job_output=$(sbatch --nodes=8 --ntasks=32 --nodelist=red[1-4],blue[1-4] \
    -o demo-ep-D-32-8.out -e demo-ep-D-32-8.err \
    --wrap="srun --mpi=pmix /mnt/hpc_shared/NPB3.4.3/NPB3.4-MPI/bin/ep.D.x")

  # Extract job ID from sbatch output
  jobid=$(echo "$job_output" | awk '{print $4}')

  echo "$(date '+%Y-%m-%d %H:%M:%S') | Submitted job $jobid from $TARGET_DIR" | tee -a "$LOG_FILE"
)
