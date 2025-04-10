process SPACERANGER_COUNT {
    tag "$meta.id"
    label 'process_high'

    container "nf-core/spaceranger:3.1.3"

    input:
    tuple val(meta), path(reads), path(image), val(slide), val(area), path(cytaimage), path(darkimage), path(colorizedimage), path(alignment), path(slidefile)
    path(reference)
    path(probeset)

    output:
    tuple val(meta), path("outs/**"), emit: outs
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "SPACERANGER_COUNT module does not support Conda. Please use Docker / Singularity / Podman instead."
    }
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // Add flags for optional inputs on demand.
    def probeset = probeset ? "--probe-set=\"${probeset}\"" : ""
    def alignment = alignment ? "--loupe-alignment=\"${alignment}\"" : ""
    def slidefile = slidefile ? "--slidefile=\"${slidefile}\"" : ""
    def image = image ? "--image=\"${image}\"" : ""
    def cytaimage = cytaimage ? "--cytaimage=\"${cytaimage}\"" : ""
    def darkimage = darkimage ? "--darkimage=\"${darkimage}\"" : ""
    def colorizedimage = colorizedimage ? "--colorizedimage=\"${colorizedimage}\"" : ""
    if (slide.matches("visium-(.*)") && area == "" && slidefile == "") {
        slide_and_area = "--unknown-slide=\"${slide}\""
    } else {
        slide_and_area = "--slide=\"${slide}\" --area=\"${area}\""
    }
    """
    spaceranger count \\
        --id="${prefix}" \\
        --sample="${meta.id}" \\
        --fastqs=. \\
        --transcriptome="${reference}" \\
        --localcores=${task.cpus} \\
        --localmem=${task.memory.toGiga()} \\
        $image $cytaimage $darkimage $colorizedimage \\
        $slide_and_area \\
        $probeset \\
        $alignment \\
        $slidefile \\
        $args
    mv ${prefix}/outs outs

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spaceranger: \$(spaceranger -V | sed -e "s/spaceranger spaceranger-//g")
    END_VERSIONS
    """

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "SPACERANGER_COUNT module does not support Conda. Please use Docker / Singularity / Podman instead."
    }
    """
    mkdir -p outs/
    touch outs/fake_file.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spaceranger: \$(spaceranger -V | sed -e "s/spaceranger spaceranger-//g")
    END_VERSIONS
    """
}
