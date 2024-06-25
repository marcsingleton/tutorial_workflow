"""Snakemake pipeline for book text analysis."""

import os
from collections import namedtuple
from glob import glob

# Paths
output_path = 'results_smk'
data_path = 'data'
code_path = 'code'

# Collect metadata
MetaRecord = namedtuple('MetaRecord', ['genre', 'title'])

META = []
for path in glob(f'{data_path}/*/*.txt'):
    head, tail = os.path.split(path)
    title = os.path.splitext(tail)[0]
    genre = os.path.basename(head)
    META.append(MetaRecord(genre, title))

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
        expand(f'{output_path}/' + '{meta.genre}/{meta.title}_stats.tsv', meta=META)
    
    output:
        f'{output_path}/basic_stats.tsv'
    
    shell:
        f'''
        for file in {{input}}
        do
            echo $file
        done >> {output_path}/basic_stats.tsv
        '''