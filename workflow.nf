// Nextflow pipeline for book text analysis

// Paths
params.output_path = "$projectDir/results_nf/"
params.data_path = "$projectDir/data/"
params.code_path = "$projectDir/code/"
params.env_path = "$projectDir/env.yaml"

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
    conda params.env_path

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

process group_jsd_stats {
    publishDir "$params.output_path/"
    conda params.env_path

    input:
    path input_path

    output:
    path "grouped_jsd.txt"

    script:
    """
    python $params.code_path/group_jsd_stats.py $input_path grouped_jsd.txt
    """

}

workflow {
    // Find paths to data and convert into tuples with metadata
    file_paths = channel.fromPath("$params.data_path/*/*.txt")
    file_records = file_paths.map({tuple([title: it.baseName, genre: it.parent.baseName], it)})
    
    // Remove header and footer and count words
    clean_records = remove_pg(file_records)
    count_records = count_words(clean_records)
    
    // Calculate basic stats of counts
    basic_records = basic_stats(count_records)
    basic_merged = paste_ids(basic_records)
        .collectFile(name: "$params.output_path/basic_stats.tsv",
                     keepHeader: true, skip: 1, sort: true)
    
    // Calculate pairwise similarity measure and aggregate stats
    count_pairs = count_records
        .combine(count_records)
        .map({
            meta1 = it[0].collectEntries((key, value) -> [key + '1', value])
            meta2 = it[2].collectEntries((key, value) -> [key + '2', value])
            meta = meta1 + meta2
            tuple(meta, it[1], it[3])
            })
        .unique({[it[0].title1, it[0].title2].sort()})
    jsd_records = jsd_divergence(count_pairs)
    jsd_merged = jsd_records
        .map({
            record = it[0].clone()  // Copy meta object to not modify
            record['jsd'] = it[1]
            keys = ['genre1', 'title1', 'genre2', 'title2', 'jsd']
            header = keys.join('\t') + '\n'
            values = keys.collect({record[it]}).join('\t') + '\n'
            header + values
            })
        .collectFile(name: "$params.output_path/jsd_divergence.tsv",
                     keepHeader: true, skip: 1, sort: true)
    group_jsd_records = group_jsd_stats(jsd_merged)
}
