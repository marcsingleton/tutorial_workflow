// Nextflow pipeline for book text analysis

// Paths
params.output_path = "$projectDir/results_nf/"
params.data_path = "$projectDir/data/"
params.code_path = "$projectDir/code/"

process remove_pg {
    publishDir "$params.output_path/"

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
    publishDir "$params.output_path/"

    input:
    tuple path(input_path), val(genre), val(title)

    output:
    tuple path("$genre/${title}_counts.tsv"), val(genre), val(title)
    
    script:
    """
    python $params.code_path/count_words.py $input_path $genre/${title}_counts.tsv
    """
}

process basic_stats {
    publishDir "$params.output_path/"

    input:
    tuple path(input_path), val(genre), val(title)

    output:
    tuple path("$genre/${title}_stats.tsv"), val(genre), val(title)

    script:
    """
    python $params.code_path/basic_stats.py $input_path $genre/${title}_stats.tsv
    """
}

process paste_ids {
    input:
    tuple path(input_path), val(genre), val(title)

    output:
    stdout

    shell:
    '''
    echo 'genre\ttitle\n!{genre}\t!{title}\n' | paste - !{input_path}
    '''
}

process jsd_divergence {
    input:
    tuple(
        path(input_path_1, stageAs: "counts1.tsv"), val(genre_1), val(title_1),
        path(input_path_2, stageAs: "counts2.tsv"), val(genre_2), val(title_2)
    )

    output:
    tuple(
        stdout,
        val(genre_1), val(title_1),
        val(genre_2), val(title_2)
    )

    script:
    """
    python $params.code_path/jsd_divergence.py $input_path_1 $input_path_2 
    """
}

workflow {
    file_paths = channel.fromPath("$params.data_path/*/*.txt")
    file_records = file_paths.map({[it, it.parent.baseName, it.baseName]})
    clean_records = remove_pg(file_records)
    count_records = count_words(clean_records)
    basic_records = basic_stats(count_records)
    paste_ids(basic_records)
        .collectFile(name: "$params.output_path/basic_stats.tsv",
                     keepHeader: true, skip: 1, sort: true)
    count_pairs = count_records.combine(count_records)
        .unique({[it[2], it[5]].sort()})
    jsd_records = jsd_divergence(count_pairs)
        .map({"title_1\ttitle_2\tjsd\n${it[2]}\t${it[4]}\t${it.value}\n"})
        .collectFile(name: "$params.output_path/jsd_divergence.tsv",
                     keepHeader: true, skip: 1, sort: true)
}
