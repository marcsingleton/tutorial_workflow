// Nextflow pipeline for book text analysis

// Paths
params.output_path = "$projectDir/results_nf/"
params.data_path = "$projectDir/data/"
params.code_path = "$projectDir/code/"

process remove_pg {
    publishDir "$params.output_path/remove_pg/"

    input:
    tuple path(input_path), val(genre), val(title)
    
    output:
    tuple path("$genre/${title}_clean.txt"), val(genre), val(title)
    
    script:
    """
    python $params.code_path/remove_pg.py $input_path $genre/${title}_clean.txt
    """
}

process count_words {
    publishDir "$params.output_path/count_words/"

    input:
    tuple path(input_path), val(genre), val(title)

    output:
    tuple path("$genre/${title}_counts.tsv"), val(genre), val(title)
    
    script:
    """
    python $params.code_path/count_words.py $input_path $genre/${title}_counts.tsv
    """
}

workflow {
    file_paths = channel.fromPath("$params.data_path/*/*.txt")
    file_records = file_paths.map({[it, it.parent.baseName, it.baseName]})
    clean_records = remove_pg(file_records)
    count_records = count_words(clean_records)
}
