// Nextflow pipeline for book text analysis

// Paths
params.output_path = "$projectDir/results_nf/"
params.data_path = "$projectDir/data/"
params.code_path = "$projectDir/code/"

process remove_pg {
    publishDir "$params.output_path/"

    input:
    tuple val(meta), val(input_path)
    
    output:
    tuple val(meta), path("${meta.genre}/${meta.title}_clean.txt")
    
    script:
    """
    python $params.code_path/remove_pg.py $input_path ${meta.genre}/${meta.title}_clean.txt
    """
}

process count_words {
    publishDir "$params.output_path/"

    input:
    tuple val(meta), path(input_path)

    output:
    tuple val(meta), path("${meta.genre}/${meta.title}_counts.tsv")
    
    script:
    """
    python $params.code_path/count_words.py $input_path ${meta.genre}/${meta.title}_counts.tsv
    """
}

process basic_stats {
    publishDir "$params.output_path/"

    input:
    tuple val(meta), path(input_path)

    output:
    tuple val(meta), path("${meta.genre}/${meta.title}_stats.tsv")

    script:
    """
    python $params.code_path/basic_stats.py $input_path ${meta.genre}/${meta.title}_stats.tsv
    """
}

process paste_ids {
    input:
    tuple val(meta), path(input_path)

    output:
    stdout

    shell:
    '''
    echo -n 'genre\ttitle\n!{meta.genre}\t!{meta.title}\n' | paste - !{input_path}
    '''
}

process jsd_divergence {
    input:
    tuple(
        val(meta),
        path(input_path_1, stageAs: "counts1.tsv"),
        path(input_path_2, stageAs: "counts2.tsv")
    )

    output:
    tuple(
        val(meta),
        stdout
    )

    script:
    """
    python $params.code_path/jsd_divergence.py $input_path_1 $input_path_2 
    """
}

workflow {
    file_paths = channel.fromPath("$params.data_path/*/*.txt")
    file_records = file_paths.map({tuple([title: it.baseName, genre: it.parent.baseName], it)})
    clean_records = remove_pg(file_records)
    count_records = count_words(clean_records)
    basic_records = basic_stats(count_records)
    paste_ids(basic_records)
        .collectFile(name: "$params.output_path/basic_stats.tsv",
                     keepHeader: true, skip: 1, sort: true)
    count_pairs = count_records
        .combine(count_records)
        .map({
            meta1 = it[0]
            meta2 = it[2]
            meta = 
                [
                title1: meta1.title, genre1: meta1.genre,
                title2: meta2.title, genre2: meta2.genre
                ]
            tuple(meta, it[1], it[3])
            })
        .unique({[it[0].title1, it[0].title2].sort()})
    jsd_records = jsd_divergence(count_pairs)
    jsd_records
        .map({"genre1\ttitle_1\tgenre_2\ttitle_2\tjsd\n${it[0].genre1}\t${it[0].title1}\t${it[0].genre2}\t${it[0].title2}\t${it[1]}\n"})
        .collectFile(name: "$params.output_path/jsd_divergence.tsv",
                     keepHeader: true, skip: 1, sort: true)
}
