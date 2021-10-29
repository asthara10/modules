// Import generic module functions
include { initOptions; saveFiles; getSoftwareName; getProcessName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process FLYE {
    tag "$meta.id"
    label 'process_high'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['id']) }

    conda (params.enable_conda ? "flye==2.9--py38h69e0bdc_0" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/flye:2.9--py39h39abbe0_0"
    } else {
        container "quay.io/biocontainers/flye:2.9--py38h69e0bdc_0"
    }

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.fasta.gz"), emit: fasta
    tuple val(meta), path("*.gfa.gz")  , emit: gfa
    tuple val(meta), path("*.gv.gz")   , emit: gv
    tuple val(meta), path("*.txt.gz")  , emit: txt
    tuple val(meta), path("*.log.gz")  , emit: log
    tuple val(meta), path("*.json.gz") , emit: json
    path "versions.yml"             , emit: versions

    script:
    def prefix = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    def mode = meta.mode
    """
    flye \\
        --$mode \\
        $reads \\
        $options.args \\
        --threads $task.cpus \\
        --out-dir ./

    gzip -c assembly.fasta > ${prefix}.assembly.fasta.gz
    gzip -c assembly_graph.gfa > ${prefix}.assembly_graph.gfa.gz
    gzip -c assembly_graph.gv > ${prefix}.assembly_graph.gv.gz
    gzip -c assembly_info.txt > ${prefix}.assembly_info.txt.gz
    gzip -c flye.log > ${prefix}.flye.log.gz
    gzip -c params.json > ${prefix}.params.json.gz

    cat <<-END_VERSIONS > versions.yml
    ${getProcessName(task.process)}:
        ${getSoftwareName(task.process)}: \$( flye --version | sed 's/-b1768//' )
    END_VERSIONS
    """
}
