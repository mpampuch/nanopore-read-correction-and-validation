process FASTQC {
    tag "$reads.baseName"
    label 'process_medium'
    publishDir "${params.outdir}/fastqc", mode: 'copy'

    input:
    path reads

    output:
    path "*.{html,zip}", emit: reports
    path "versions.yml", emit: versions

    script:
    """
    # Create output directory
    mkdir -p fastqc_output

    # Run FastQC
    fastqc \\
        --quiet \\
        --threads ${task.cpus} \\
        --outdir fastqc_output \\
        ${reads}

    # Move outputs to current directory
    mv fastqc_output/* .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastqc: \$(fastqc --version | sed '/FastQC v/!d; s/.*v//')
    END_VERSIONS
    """

    stub:
    """
    touch ${reads.baseName}_fastqc.html
    touch ${reads.baseName}_fastqc.zip
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastqc: \$(fastqc --version | sed '/FastQC v/!d; s/.*v//')
    END_VERSIONS
    """
}