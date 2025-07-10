process YAK_QV {
    tag "$sample_id"
    label 'process_medium'
    publishDir "${params.outdir}/quality_values", mode: 'copy'

    input:
    tuple val(illumina_id), path(illumina_yak)
    tuple val(sample_id), path(nanopore_reads)

    output:
    tuple val(sample_id), path("*.qv"), emit: qv_results
    tuple val(sample_id), path("*.txt"), emit: qv_summary
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    def input_cmd = nanopore_reads.name.endsWith('.gz') ? "zcat ${nanopore_reads}" : "cat ${nanopore_reads}"
    """
    # Calculate quality values for nanopore reads against Illumina k-mer database
    yak qv \\
        -t ${task.cpus} \\
        -K ${params.kmer_size} \\
        ${args} \\
        ${illumina_yak} \\
        <(${input_cmd}) \\
        > ${sample_id}_qv_results.qv

    # Extract summary statistics
    echo "Sample: ${sample_id}" > ${sample_id}_qv_summary.txt
    echo "Analysis timestamp: \$(date)" >> ${sample_id}_qv_summary.txt
    echo "K-mer size: ${params.kmer_size}" >> ${sample_id}_qv_summary.txt
    echo "Illumina reference: ${illumina_id}" >> ${sample_id}_qv_summary.txt
    echo "" >> ${sample_id}_qv_summary.txt
    
    # Calculate basic statistics from QV output
    if [ -s ${sample_id}_qv_results.qv ]; then
        echo "QV Statistics:" >> ${sample_id}_qv_summary.txt
        awk '
        BEGIN { 
            sum=0; count=0; min=999; max=0 
        } 
        NF==2 && \$2 ~ /^[0-9]/ { 
            sum+=\$2; count++; 
            if(\$2<min) min=\$2; 
            if(\$2>max) max=\$2 
        } 
        END { 
            if(count>0) {
                printf "  Mean QV: %.2f\\n", sum/count
                printf "  Min QV: %.2f\\n", min
                printf "  Max QV: %.2f\\n", max
                printf "  Total reads analyzed: %d\\n", count
            } else {
                print "  No valid QV data found"
            }
        }' ${sample_id}_qv_results.qv >> ${sample_id}_qv_summary.txt
    else
        echo "  No QV data generated" >> ${sample_id}_qv_summary.txt
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        yak: \$(yak version 2>&1 | head -n1 | sed 's/^.*yak-//; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    """
    touch ${sample_id}_qv_results.qv
    touch ${sample_id}_qv_summary.txt
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        yak: \$(yak version 2>&1 | head -n1 | sed 's/^.*yak-//; s/ .*\$//')
    END_VERSIONS
    """
}