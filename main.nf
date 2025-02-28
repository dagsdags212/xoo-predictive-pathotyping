include { FETCH_METADATA } from './modules/fetch_metadata'
include { FETCH_ASSEMBLIES } from './modules/download_data'

workflow {
    // FETCH_METADATA()
    Channel
      .fromPath("./metadata/xoo_assembly_ids.txt")
      .set { assembly_ids }

    FETCH_ASSEMBLIES(assembly_ids, "xoo_assemblies")
}