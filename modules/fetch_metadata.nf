
process FETCH_XOO_ASSEMBLIES {

  container 'community.wave.seqera.io/library/entrez-direct_ncbi-datasets-cli:803ef2ef7c10175e'

  publishDir 'metadata'

  output:
    path 'xoo_assembly_ids.txt'

  script:
  """
  esearch -db assembly -query 'Xanthomonas oryzae pv. oryzae' \
    | efilter -status latest \
    | esummary \
    | xtract -pattern DocumentSummary \
        -if AssemblyStatus -starts-with Complete \
        -and Coverage -gt 60 \
        -element AssemblyAccession \
    | uniq | sort > xoo_assembly_ids.txt
  """
}

process FETCH_XOO_READS_METADATA {

  container 'community.wave.seqera.io/library/entrez-direct_ncbi-datasets-cli:803ef2ef7c10175e'

  publishDir 'metadata'

  output:
    path 'xoo_read_metadata.xml'

  script:
  """
  esearch -db sra -query "Xanthomonas oryzae pv. oryzae" \
    | esummary > xoo_read_metadata.xml
  """
}

process FILTER_SHORT_READS_FROM_METADATA {

  container 'community.wave.seqera.io/library/entrez-direct_ncbi-datasets-cli:803ef2ef7c10175e'

  publishDir 'metadata'

  input:
    path metadata

  output:
    path 'xoo_short_reads_metadata.csv'

  script:
  """
  cat $metadata \
    | xtract -pattern DocumentSummary \
      -if Platform -is-not OXFORD_NANOPORE \
      -and Platform -is-not PACBIO_SMRT \
      -tab ',' -def '-' -sep ';' -element Bioproject Biosample Run@acc \
    > xoo_short_reads_metadata.csv \
  """
}

process FILTER_LONG_READS_FROM_METADATA {

  container 'community.wave.seqera.io/library/entrez-direct_ncbi-datasets-cli:803ef2ef7c10175e'

  publishDir 'metadata'

  input:
    path metadata

  output:
    path 'xoo_long_reads_metadata.csv'

  script:
  """
  cat $metadata \
    | xtract -pattern DocumentSummary \
      -if Platform -equals OXFORD_NANOPORE \
      -or Platform -equals PACBIO_SMRT \
      -tab ',' -def '-' -sep ';' -element Bioproject Biosample Run@acc \
    > xoo_long_reads_metadata.csv \
  """
}

process EXTRACT_SHORT_READ_ACCESSIONS {
  publishDir 'metadata'

  input:
    path metadata_file

  output:
    path "*.txt"
  
  script:
  """
  cat $metadata_file | cut -d, -f3 | tr ';' '\n' > short_read_accessions.txt
  """
}

process EXTRACT_LONG_READ_ACCESSIONS {
  publishDir 'metadata'

  input:
    path metadata_file

  output:
    path "*.txt"
  
  script:
  """
  cat $metadata_file | cut -d, -f3 | tr ';' '\n' > long_read_accessions.txt
  """
}
process DOWNLOAD_SHORT_READS {

  container 'community.wave.seqera.io/library/sra-tools:3.2.0--7131354b4197d164'

  publishDir 'data/reads/short'

  input:
    val acc

  output:
    path 'data/reads/short/${acc}.fastq'

  script:
  """
  fastq-dump -F --split-file -O data/reads/short ${acc}
  """
}


params.short_read_acc = "${projectDir}/metadata/short_read_accessions.txt"

workflow FETCH_METADATA {
  // Retrieve a list of Xoo assemblies from NCBI.
  FETCH_XOO_ASSEMBLIES()

  // Retrieve Xoo read metadata.
  metadata = FETCH_XOO_READS_METADATA()

  // Filter metadata to only include short reads.
  short_read_metadata = FILTER_SHORT_READS_FROM_METADATA(metadata)

  // Filter metadata to only include long reads.
  long_read_metadata = FILTER_LONG_READS_FROM_METADATA(metadata)

  // Extract read accession.
  short_read_accessions = EXTRACT_SHORT_READ_ACCESSIONS(short_read_metadata)
  long_read_accessions = EXTRACT_LONG_READ_ACCESSIONS(long_read_metadata)

  short_read_accessions
}