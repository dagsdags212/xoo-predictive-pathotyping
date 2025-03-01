process FETCH_XOO_ASSEMBLIES {
  container 'oras://community.wave.seqera.io/library/entrez-direct:22.4--13b1b2ab094decff'
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
  container 'oras://community.wave.seqera.io/library/entrez-direct:22.4--13b1b2ab094decff'
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
  container 'oras://community.wave.seqera.io/library/entrez-direct:22.4--13b1b2ab094decff'
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
  container 'oras://community.wave.seqera.io/library/entrez-direct:22.4--13b1b2ab094decff'
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
    path "short_read_accessions.txt"
  
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
    path "long_read_accessions.txt"
  
  script:
  """
  cat $metadata_file | cut -d, -f3 | tr ';' '\n' > long_read_accessions.txt
  """
}

process PREFETCH_ASSEMBLIES {
    container 'community.wave.seqera.io/library/ncbi-datasets-cli:16.43.0--33e650ab1b371eba'    
    publishDir "data", mode: 'copy'

    input:
        path asm_accession_list
        val filename
    
    output:
        path "${filename}.zip"

    script:
    """
    datasets download genome accession --inputfile ${asm_accession_list} \
        --assembly-level complete --assembly-source all \
        --filename ${filename}.zip --include genome,gff3 \
        --dehydrated
    """
}

process UNZIP_ASSEMBLY_URLS {
    publishDir "data", mode: 'copy'

    input:
        path asm_dir

    output:
        path "assemblies"
    
    script:
    """
    unzip ${asm_dir} -d assemblies
    """
}

process REHYDRATE_ASSEMBLIES {
    container 'community.wave.seqera.io/library/ncbi-datasets-cli:16.43.0--33e650ab1b371eba'    
    publishDir "data", mode: 'copy'

    input:
        path asm_dir

    output:
        path "${asm_dir}/ncbi_dataset/data/GC*"

    script:
    """
    datasets rehydrate --directory ${asm_dir}
    """
}

workflow FETCH_GENOMES {
  // Retrieve all Xoo assemblies from NCBI.
  asm_list = FETCH_XOO_ASSEMBLIES()
  PREFETCH_ASSEMBLIES(asm_list, 'xoo_assemblies')
    | UNZIP_ASSEMBLY_URLS
    | REHYDRATE_ASSEMBLIES
}

workflow FETCH_READS {
  // Retrieve Xoo read metadata.
  metadata = FETCH_XOO_READS_METADATA()

  // Filter short reads and extract accessions.
  FILTER_SHORT_READS_FROM_METADATA(metadata)
    | EXTRACT_SHORT_READ_ACCESSIONS

  // Filter long reads and extract accessions.
  FILTER_LONG_READS_FROM_METADATA(metadata)
    | EXTRACT_LONG_READ_ACCESSIONS
}