#!/bin/bash

TAG="xoo_reads_download_script"

# Check if dependencies are installed.
DEPS=(fastq-dump)
for exe in "${DEPS[@]}"; do
  if ! command -v ${exe}; then
    echo "ERROR: ${exe} not installed."  
    exit -2
  fi
done

# No. of CPU threads.
THREADS=8

# No. of parallel jobs.
JOBS=3

# Filepaths to accession lists.
LR_ACCESSIONS=metadata/long_read_metadata.csv
SR_ACCESSIONS=metadata/short_read_metadata.csv

# Verify that files exist.
if [[ ! -e "${LR_ACCESSIONS}" ]]; then
   echo "ERROR: ${LR_ACCESSIONS} does not exist."
   exit -1
fi

if [[ ! -e "${SR_ACCESSIONS}" ]]; then
  echo "ERROR: ${SR_ACCESSIONS} does not exist."
  exit -1
fi

# Output directorys.
LR_OUT=data/reads/long
SR_OUT=data/reads/short

mkdir -p ${LR_OUT} ${SR_OUT}

# Count number of long reads.
lr_count=$(cut -d, -f3 ${LR_ACCESSIONS} | tr ';' '\n' | wc -l)
echo "Detected ${lr_count} LONG-READ accessions."

# Download long reads.
cut -d, -f3 | tr ';' '\n' | ${LR_ACCESSIONS} | parallel -j ${JOBS} --progress "fastq-dump -F -Z {} | gzip > ${LR_OUT}/{}.fastq.gz"

# Count number of long reads.
sr_count=$(cut -d, -f3 ${SR_ACCESSIONS} | tr ';' '\n' | wc -l)
echo "Detected ${sr_count} SHORT-READ accessions."

# Download short reads.
cut -d, -f3 | tr ';' '\n' | ${SR_ACCESSIONS} | parallel -j ${JOBS} --progress "fastq-dump -F -Z {} | gzip > ${SR_OUT}/{}.fastq.gz"
