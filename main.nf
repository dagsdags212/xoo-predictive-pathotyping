include { FETCH_GENOMES; FETCH_READS } from './modules/fetch' 

workflow {
    FETCH_GENOMES()
    FETCH_READS()
}