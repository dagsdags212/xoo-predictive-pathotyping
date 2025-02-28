process FETCH_ASSEMBLIES {
    container 'community.wave.seqera.io/library/ncbi-datasets-cli:16.43.0--33e650ab1b371eba'    

    publishDir "data", mode: 'copy'

    input:
        path asm_accession_list
        val filename

    script:
    """
    datasets download genome accession --inputfile ${asm_accession_list} \
        --assembly-level complete --assembly-source all \
        --filename ${filename}.zip --include genome,gff3
    """
}
