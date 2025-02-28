
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

  """
  cat $metadata \
    | xtract -pattern DocumentSummary \
      -if Platform -is-not OXFORD_NANOPORE \
      -and Platform -is-not PACBIO_SMRT \
      -tab ',' -sep ';' -element Bioproject Biosample Run@acc \
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

  """
  cat $metadata \
    | xtract -pattern DocumentSummary \
      -if Platform -equals OXFORD_NANOPORE \
      -or Platform -equals PACBIO_SMRT \
      -tab ',' -sep ';' -element Bioproject Biosample Run@acc \
    > xoo_long_reads_metadata.csv \
  """
}


workflow {
  // Retrieve a list of Xoo assemblies from NCBI.
  FETCH_XOO_ASSEMBLIES()

  // Retrieve Xoo read metadata.
  metadata = FETCH_XOO_READS_METADATA()

  // Filter metadata to only include short reads.
  FILTER_SHORT_READS_FROM_METADATA(metadata)

  // Filter metadata to only include long reads.
  FILTER_LONG_READS_FROM_METADATA(metadata)
}