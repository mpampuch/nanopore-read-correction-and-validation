#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

/*
 * Nextflow pipeline for assessing nanopore read quality compared to Illumina reads using yak
 * 
 * Usage:
 *   nextflow run main.nf --illumina_reads "path/to/illumina/*_{R1,R2}.fastq.gz" --nanopore_reads "path/to/nanopore/*.fastq.gz"
 */

// Pipeline parameters with defaults
params.illumina_reads = "data/illumina/*_{R1,R2}.fastq.gz"
params.nanopore_reads = "data/nanopore/*.fastq.gz"
params.outdir = "results"
params.threads = 4
params.kmer_size = 37
params.yak_bloomfilter_bits = 37
params.help = false

// Help message
def helpMessage() {
    log.info"""
    ===================================
     Yak Quality Assessment Pipeline
    ===================================
    
    Usage:
      nextflow run main.nf [options]
    
    Required arguments:
      --illumina_reads    Path to Illumina paired-end reads (e.g., "data/*_{R1,R2}.fastq.gz")
      --nanopore_reads    Path to nanopore long reads (e.g., "data/*.fastq.gz")
    
    Optional arguments:
      --outdir           Output directory (default: results)
      --threads          Number of threads (default: 4)
      --kmer_size        K-mer size for analysis (default: 37)
      --yak_bloomfilter_bits  Bloom filter bits for yak (default: 37)
      --help             Show this help message
    
    Example:
      nextflow run main.nf \\
        --illumina_reads "data/illumina/*_{R1,R2}.fastq.gz" \\
        --nanopore_reads "data/nanopore/*.fastq.gz" \\
        --outdir results \\
        --threads 8
    """.stripIndent()
}

// Show help message if requested
if (params.help) {
    helpMessage()
    exit 0
}

// Input validation
if (!params.illumina_reads || !params.nanopore_reads) {
    log.error "Please provide both --illumina_reads and --nanopore_reads parameters"
    helpMessage()
    exit 1
}

// Import modules
include { YAK_COUNT_ILLUMINA } from './modules/yak_count'
include { YAK_COUNT_NANOPORE } from './modules/yak_count'
include { YAK_QV } from './modules/yak_qv'
include { QUALITY_REPORT } from './modules/quality_report'
include { FASTQC } from './modules/fastqc'

/*
 * Main workflow
 */
workflow {
    
    // Create input channels
    illumina_ch = Channel
        .fromFilePairs(params.illumina_reads, checkIfExists: true)
        .ifEmpty { error "Cannot find any Illumina reads matching: ${params.illumina_reads}" }
    
    nanopore_ch = Channel
        .fromPath(params.nanopore_reads, checkIfExists: true)
        .ifEmpty { error "Cannot find any nanopore reads matching: ${params.nanopore_reads}" }
        .map { file -> tuple(file.baseName, file) }
    
    // Run FastQC on both read types for basic quality metrics
    FASTQC(
        illumina_ch.map { id, reads -> reads }.flatten(),
        nanopore_ch.map { id, file -> file }
    )
    
    // Count k-mers in Illumina reads using yak
    YAK_COUNT_ILLUMINA(illumina_ch)
    
    // Count k-mers in nanopore reads using yak  
    YAK_COUNT_NANOPORE(nanopore_ch)
    
    // Calculate quality values (QV) by comparing nanopore reads against Illumina k-mer database
    YAK_QV(
        YAK_COUNT_ILLUMINA.out.yak_db,
        nanopore_ch
    )
    
    // Generate comprehensive quality report
    QUALITY_REPORT(
        YAK_COUNT_ILLUMINA.out.yak_db.collect(),
        YAK_COUNT_NANOPORE.out.yak_db.collect(),
        YAK_QV.out.qv_results.collect(),
        FASTQC.out.reports.collect()
    )
}

/*
 * Workflow completion
 */
workflow.onComplete {
    if (workflow.success) {
        log.info """
        ===================================
         Pipeline completed successfully!
        ===================================
        Results are in: ${params.outdir}
        
        Key outputs:
        - Illumina k-mer database: ${params.outdir}/yak_illumina/
        - Nanopore k-mer database: ${params.outdir}/yak_nanopore/
        - Quality values: ${params.outdir}/quality_values/
        - Quality report: ${params.outdir}/quality_report.html
        - FastQC reports: ${params.outdir}/fastqc/
        """.stripIndent()
    } else {
        log.error "Pipeline failed. Check the error messages above."
    }
}