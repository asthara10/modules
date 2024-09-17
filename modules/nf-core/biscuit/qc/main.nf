process BISCUIT_QC {
    tag "$meta.id"
    label 'process_long'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/biscuit:1.1.0.20220707--he272189_1':
        'biocontainers/biscuit:1.1.0.20220707--he272189_1' }"

    input:
    tuple val(meta), path(bam)
    path(index)

    output:
    tuple val(meta), path("*.txt"), emit: biscuit_qc_reports
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def se = meta.single_end ? "-s" : ""
    """
    INDEX=`find -L ./ -name "*.bis.amb" | sed 's/\\.bis.amb\$//'`

    biscuit qc \\
        $args \\
        $se \\
        \$INDEX \\
        $bam \\
        $prefix

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        biscuit: \$( biscuit version |& sed '1!d; s/^.*BISCUIT Version: //' )
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_CpGRetentionByReadPos.txt
    touch ${prefix}_CpHRetentionByReadPos.txt
    touch ${prefix}_dup_report.txt
    touch ${prefix}_isize_table.txt
    touch ${prefix}_mapq_table.txt
    touch ${prefix}_strand_table.txt
    touch ${prefix}_totalReadConversionRate.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        biscuit: \$( biscuit version |& sed '1!d; s/^.*BISCUIT Version: //' )
    END_VERSIONS
    """
}
