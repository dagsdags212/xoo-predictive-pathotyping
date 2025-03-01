include { FETCH_METADATA } from './modules/fetch_metadata'
include { DOWNLOAD_ASSEMBLIES } from './modules/download_data'
  
params.asm_accessions = "./metadata/xoo_assembly_ids.txt"

workflow {
    FETCH_METADATA()
    Channel
      .fromPath(params.asm_accessions)
      .set { assembly_ids }

    DOWNLOAD_ASSEMBLIES(assembly_ids, "xoo_assemblies")
}