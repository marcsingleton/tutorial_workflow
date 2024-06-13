// Nextflow pipeline for book text analysis

// Paths
params.output_path = "$projectDir/results_nf/"
params.data_path = "$projectDir/data/"
params.code_path = "$projectDir/code/"

process remove_pg {
    publishDir "$params.output_path/remove_pg/"

    input:
        tuple val(genre), val(title)
    
    output:
        path "$genre/${title}_clean.txt"
    
    script:
    """
    python $params.code_path/remove_pg.py $params.data_path/$genre/${title}.txt $genre/${title}_clean.txt
    """
}

workflow {
    file_paths = channel.fromPath("$params.data_path/*/*.txt", relative: true)
    file_tuples = file_paths.map({[it.parent, it.baseName]})
    output = remove_pg(file_tuples)
    output.view()
}