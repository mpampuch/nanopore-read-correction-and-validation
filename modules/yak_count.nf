process YAK_COUNT_ILLUMINA {
    tag "$sample_id"
    label 'process_high'
    publishDir "${params.outdir}/yak_illumina", mode: 'copy'

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("*.yak"), emit: yak_db
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    # Count k-mers from Illumina paired-end reads
    yak count \\
        -k ${params.kmer_size} \\
        -b ${params.yak_bloomfilter_bits} \\
        -t ${task.cpus} \\
        -o ${sample_id}_illumina.yak \\
        ${args} \\
        <(zcat ${reads[0]}) <(zcat ${reads[1]})

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        yak: \$(yak version 2>&1 | head -n1 | sed 's/^.*yak-//; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    """
    touch ${sample_id}_illumina.yak
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        yak: \$(yak version 2>&1 | head -n1 | sed 's/^.*yak-//; s/ .*\$//')
    END_VERSIONS
    """
}

process YAK_COUNT_NANOPORE {
    tag "$sample_id"
    label 'process_high'
    publishDir "${params.outdir}/yak_nanopore", mode: 'copy'

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("*.yak"), emit: yak_db
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    def input_cmd = reads.name.endsWith('.gz') ? "zcat ${reads}" : "cat ${reads}"
    """
    # Count k-mers from nanopore long reads
    yak count \\
        -k ${params.kmer_size} \\
        -b ${params.yak_bloomfilter_bits} \\
        -t ${task.cpus} \\
        -o ${sample_id}_nanopore.yak \\
        ${args} \\
        <(${input_cmd})

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        yak: \$(yak version 2>&1 | head -n1 | sed 's/^.*yak-//; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    """
    touch ${sample_id}_nanopore.yak
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        yak: \$(yak version 2>&1 | head -n1 | sed 's/^.*yak-//; s/ .*\$//')
    END_VERSIONS
    """
}