process BLAST_BLASTDBCMD {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/52/5222a42b366a0468a4c795f5057c2b8cfe39489548f8bd807e8ac0f80069bad5/data':
        'community.wave.seqera.io/library/blast:2.16.0--540f4b669b0a0ddd' }"

    input:
    tuple val(meta) , val(entry), path(entry_batch)
    tuple val(meta2), path(db)

    output:
    tuple val(meta), path("*.fasta"), optional: true, emit: fasta
    tuple val(meta), path("*.txt")  , optional: true, emit: text
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    assert (!entry && entry_batch) || (entry && !entry_batch) : "ERROR: You must use either entry or entry_batch, not both at the same time"
    def input = ''
    if (entry) {
        input = "-entry ${entry}"
    } else {
        input = "-entry_batch ${entry_batch}"
    }
    def extension  = args.contains("-outfmt") && !args.contains("-outfmt %f") ? "txt" : "fasta"
    """
    DB=`find -L ./ -name "*.nhr" | sed 's/\\.nhr\$//'`
    if test -z "\$DB"
    then
        DB=`find -L ./ -name "*.phr" | sed 's/\\.phr\$//'`
    fi

    blastdbcmd \\
        -db \$DB \\
        ${args} \\
        -out ${prefix}.${extension} \\
        ${input}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        blast: \$(blastdbcmd -version 2>&1 | head -n1 | sed 's/^.*blastdbcmd: //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def extension  = args.contains("-outfmt") && !args.contains("-outfmt %f") ? "txt" : "fasta"
    """
    touch ${prefix}.${extension}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        blast: \$(blastdbcmd -version 2>&1 | head -n1 | sed 's/^.*blastdbcmd: //; s/ .*\$//')
    END_VERSIONS
    """
}
