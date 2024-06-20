"""Compute basic statistics of word counts."""

import os
from argparse import ArgumentParser

import pandas as pd
import scipy.stats as stats


def get_median(dist):
    l0 = 0
    cumsum = 0
    for l, p in dist.items():
        cumsum += p
        if cumsum >= 0.5:
            t = (0.5 - cumsum + p) / p
            return t * l + (1 - t) * l0
        l0 = l


if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument('input_path')
    parser.add_argument('output_path')
    args = parser.parse_args()

    df = pd.read_table(args.input_path)
    df['word_len'] = df['word'].apply(len)

    vocab_size = len(df)
    vocab_size_GT1 = (df['count'] > 1).sum()
    vocab_size_L90 = ((df['count'] / df['count'].sum()).cumsum() <= 0.9).sum() + 1  # Analogous to genome assembly statistic L50
    longest_word = df.sort_values(['word_len', 'word'],
                                  ascending=[False, True],
                                  ignore_index=True).at[0, 'word']
    most_common_word = df.at[0, 'word']
    entropy = stats.entropy(df['count'])

    length_dist = df.groupby('word_len')['count'].sum()
    length_dist = length_dist / length_dist.sum()
    min_word_length = length_dist.index.min()
    max_word_length = length_dist.index.max()
    median_word_length = get_median(length_dist)
    mean_word_length = (length_dist.index * length_dist).sum()
    var_word_length = (length_dist * (length_dist.index - mean_word_length) ** 2).sum()

    output = [
        ("vocab_size", vocab_size),
        ("vocab_size_GT1", vocab_size_GT1),
        ("vocab_size_L90", vocab_size_L90),
        ("longest_word", longest_word),
        ("most_common_word", most_common_word),
        ("entropy", entropy),
        ("min_word_length", min_word_length),
        ("max_word_length", max_word_length),
        ("median_word_length", median_word_length),
        ("mean_word_length", mean_word_length),
        ("var_word_length", var_word_length)
        ]

    output_dir = os.path.dirname(args.output_path)
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    with open(args.output_path, 'w') as file:
        header = '\t'.join([record[0] for record in output]) + '\n'
        values = '\t'.join([str(record[1]) for record in output]) + '\n'
        file.write(header + values)
