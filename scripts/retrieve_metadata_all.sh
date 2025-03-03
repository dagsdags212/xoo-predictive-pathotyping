#!/bin/bash

echo "Checking dependencies..."
DEPS=(esearch efilter esummary xtract)
for exe in "${DEPS[@]}"; do
  if ! command -v ${exe}; then
    echo "ERROR: ${exe} not installed."  
    exit -2
  fi
done

# Create metadata directory.
mkdir -p metadata

confirm_overwrite() {
  local file=$1
  local fn=$2

  if [[ -f "${file}" ]]; then
    read -p "File (${file}) already exists. Overwrite it? [Y,n] " choice
    case ${choice} in
      Y|y) $2 ;;
      *) echo "Skipping file overwrite" ;;
    esac
  else
    $2
  fi
}

# Paths to output files.
ASM_METADATA=metadata/assembly_metadata.xml
ASM_IDS=metadata/assembly_ids.txt

retrieve_asm_metadata() {
  # Fetch NCBI assembly metadata for Xoo.
  esearch -db assembly -query "Xanthomonas oryzae pv. oryzae" \
    | efilter -status latest \
    | esummary > ${ASM_METADATA}
}

extract_asm_accessions() {  
  ## Verify that file for assembly metadata, else exit.
  [[ -f "${ASM_METADATA}" ]] || exit -1;

  ## Filter assemblies and retrieve accession list.
  cat ${ASM_METADATA} \
    | xtract -pattern DocumentSummary \
        -if AssemblyStatus -starts-with Complete \
        -and Coverage -gt 60 \
        -element AssemblyAccession \
    | uniq | sort > ${ASM_IDS}
}

# Output files for read metadata.
SRA_METADATA=metadata/read_metadata.xml
SR_METADATA=metadata/short_read_metadata.csv
LR_METADATA=metadata/long_read_metadata.csv

retrieve_read_metadata() {
  # Fetch all metadata for Xoo reads.
  esearch -db sra -query "Xanthomonas oryzae pv. oryzae " \
    | esummary > ${SRA_METADATA}
}

filter_short_read_accessions() {
  # Confirm SRA metadata file exists.
  [[ -f "${SRA_METADATA}" ]] || exit -1;

  # Filter short-read accessions.
  cat ${SRA_METADATA} \
    | xtract -pattern DocumentSummary \
        -if Platform -is-not OXFORD_NANOPORE \
        -and Platform -is-not PACBIO_SMRT \
        -tab ',' -def '-' -sep ';' -element Bioproject Biosample Run@acc \
    > ${SR_METADATA}
}

filter_long_read_accessions() {
  
  # Confirm SRA metadata file exists.
  [[ -f "${SRA_METADATA}" ]] || exit -1;

  # Filter long-read accessions.
  cat ${SRA_METADATA} \
    | xtract -pattern DocumentSummary \
        -if Platform -equals OXFORD_NANOPORE \
        -or Platform -equals PACBIO_SMRT \
        -tab ',' -def '-' -sep ';' -element Bioproject Biosample Run@acc \
    > ${LR_METADATA}
}

retrieve_asm_metadata
extract_asm_accessions

retrieve_read_metadata
filter_short_read_accessions
filter_long_read_accessions

# Overwrite assembly metadata?
#confirm_overwrite ${ASM_METADATA} retrieve_asm_metadata

# Overwrite list of assembly IDs?
#confirm_overwrite ${ASM_IDS} extract_asm_accessions

# Overwrite SRA metadata?
#confirm_overwrite ${SRA_METADATA} retrieve_read_metadata

# Overwrite short-read metadata?
#confirm_overwrite ${SR_METADATA} filter_short_read_accessions

# Overwrite long-read metadata?
#confirm_overwrite ${LR_METADATA} filter_long_read_accessions
