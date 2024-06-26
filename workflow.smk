"""Snakemake pipeline for book text analysis."""

import os
from collections import namedtuple
from glob import glob

# Paths
output_path = 'results_smk'
data_path = 'data'
code_path = 'code'

# Collect metadata
genres, titles = glob_wildcards(f'{data_path}/{{genre}}/{{title}}.txt')

rule remove_pg:
    input:
        f'{data_path}/{{genre}}/{{title}}.txt'

    output:
        f'{output_path}/{{genre}}/{{title}}_clean.txt'

    shell:
        f'''
        python {code_path}/remove_pg.py {{input}} {{output}}
        '''

rule count_words:
    input:
        rules.remove_pg.output
    
    output:
        f'{output_path}/{{genre}}/{{title}}_counts.txt'
    
    shell:
        f'''
        python {code_path}/count_words.py {{input}} {{output}}
        '''

rule basic_stats:
    input:
        rules.count_words.output

    output:
        f'{output_path}/{{genre}}/{{title}}_stats.tsv'

    shell:
        f'''
        python {code_path}/basic_stats.py {{input}} {{output}}
        '''

rule merge_basic_stats:
    input:
        expand(rules.basic_stats.output, zip, genre=genres, title=titles)
    
    output:
        f'{output_path}/basic_stats.tsv'
    
    shell:
        '''
        read -a files <<< "{input}"
        echo -n "genre\ttitle\t" > {output}
        head -n 1 ${{files[0]}} >> {output}
        for file in "${{files[@]}}"
        do
            base=$(basename $file)
            title=${{base%_stats.tsv}}
            genre=$(basename $(dirname $file))
            echo -n "$genre\t$title\t"
            tail -n +2 $file
        done | sort >> {output}
        '''