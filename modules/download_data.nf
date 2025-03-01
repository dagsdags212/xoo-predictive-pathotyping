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

workflow DOWNLOAD_ASSEMBLIES {
    take:
        asm_accession_list
        filename

    main:
        PREFETCH_ASSEMBLIES(asm_accession_list, filename)
        UNZIP_ASSEMBLY_URLS(PREFETCH_ASSEMBLIES.out)
        REHYDRATE_ASSEMBLIES(UNZIP_ASSEMBLY_URLS.out)

    emit:
        REHYDRATE_ASSEMBLIES.out
}