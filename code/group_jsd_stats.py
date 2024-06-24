"""Calculate meta-statistics from the pairwise JSD values."""

import os
from argparse import ArgumentParser
from textwrap import dedent

import pandas as pd
from scipy.stats import mannwhitneyu

if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument('input_path')
    parser.add_argument('output_path')
    args = parser.parse_args()

    df = pd.read_table(args.input_path)
    
    df['intra'] = df['genre1'] == df['genre2']
    intra = df.loc[df['intra'] & (df['title1'] != df['title2']), 'jsd']
    inter = df.loc[~df['intra'], 'jsd']
    result = mannwhitneyu(intra, inter)

    output = dedent(f"""\
    inter_mean: {inter.mean()}
    inter_median: {inter.median()}
    inter_var: {inter.var()}
    
    intra_mean: {intra.mean()}
    intra_median: {intra.median()}
    intra_var: {intra.var()}

    mannwhitneyu_statistic: {result.statistic}
    mannwhitneyu_pvalue: {result.pvalue}
    """)

    output_dir = os.path.dirname(args.output_path)
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    with open(args.output_path, 'w') as file:
        file.write(output)
