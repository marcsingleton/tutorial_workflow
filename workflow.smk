"""Snakemake pipeline for book text analysis."""

import os
from itertools import combinations_with_replacement

# Paths
output_path = 'results_smk'
data_path = 'data'
code_path = 'code'
env_path = 'env.yaml'

# Collect metadata
GENRES, TITLES = glob_wildcards(f'{data_path}/{{genre}}/{{title}}.txt')
META = list(zip(GENRES, TITLES))

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
        f'{output_path}/{{genre}}/{{title}}_counts.tsv'
    shell:
        f'''
        python {code_path}/count_words.py {{input}} {{output}}
        '''

rule basic_stats:
    input:
        rules.count_words.output
    output:
        f'{output_path}/{{genre}}/{{title}}_stats.tsv'
    conda:
        env_path
    shell:
        f'''
        python {code_path}/basic_stats.py {{input}} {{output}}
        '''

rule merge_basic_stats:
    input:
        expand(rules.basic_stats.output, zip, genre=GENRES, title=TITLES)
    output:
        f'{output_path}/basic_stats.tsv'
    shell:
        '''
        read -a files <<< "{input}"
        echo -n "genre\ttitle\t" > "{output}"
        head -n 1 ${{files[0]}} >> "{output}"
        for file in "${{files[@]}}"
        do
            base=$(basename $file)
            title=${{base%%_*}}
            genre=$(basename $(dirname $file))
            echo -n "$genre\t$title\t"
            tail -n +2 $file
        done | sort >> "{output}"
        '''

rule jsd_divergence:
    input:
       file1 = rules.count_words.output[0].replace('genre', 'genre1').replace('title', 'title1'),
       file2 = rules.count_words.output[0].replace('genre', 'genre2').replace('title', 'title2')
    output:
        temp(f'{output_path}/jsd_divergence/{{genre1}}|{{title1}}|{{genre2}}|{{title2}}.temp')
    shell:
        f'''
        python {code_path}/jsd_divergence.py {{input.file1}} {{input.file2}} > "{{output}}"
        '''

META1, META2 = zip(*combinations_with_replacement(META, 2))
GENRES1, TITLES1 = zip(*META1)
GENRES2, TITLES2 = zip(*META2)
rule merge_jsd_divergence:
    input:
        expand(rules.jsd_divergence.output, zip, genre1=GENRES1, title1=TITLES1, genre2=GENRES2, title2=TITLES2)
    output:
        f'{output_path}/jsd_divergence.tsv'
    shell:
        '''
        read -a files <<< "{input}"
        echo "genre1\ttitle1\tgenre2\ttitle2\tjsd" > "{output}"
        for file in "${{files[@]}}"
        do
            base=$(basename $file)
            meta=${{base%%.*}}
            jsd=$(cat $file)
            echo "$meta\t$jsd" | tr "|" "\t"
        done | sort >> "{output}"
        '''

rule group_jsd_stats:
    input:
        rules.merge_jsd_divergence.output
    output:
        f'{output_path}/grouped_jsd.txt'
    conda:
        env_path
    shell:
        f'''
        python {code_path}/group_jsd_stats.py {{input}} {{output}}
        '''

rule all:
    default_target: True
    input:
        rules.merge_basic_stats.output,
        rules.group_jsd_stats.output
