"""Calculate the symmetric KL divergence (Jensen–Shannon divergence) of two word count distributions."""

from argparse import ArgumentParser
from math import log


def read_counts(input_path):
    counts = {}
    with open(input_path) as file:
        file.readline()
        for line in file:
            fields = line.rstrip('\n').split('\t')
            word, count = fields[0], int(fields[1])
            counts[word] = count
    return counts


if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument('input_path_1')
    parser.add_argument('input_path_2')
    args = parser.parse_args()

    counts1 = read_counts(args.input_path_1)
    counts2 = read_counts(args.input_path_2)

    vocab = set(counts1) | set(counts2)
    pseudo_count = 1 / len(vocab)  # Use 1 pseudo-count uniform across all words
    n1 = sum(counts1.values()) + 1
    n2 = sum(counts2.values()) + 1

    JSD = 0
    for word in vocab:
        p1 = (counts1.get(word, 0) + pseudo_count) / n1
        p2 = (counts2.get(word, 0) + pseudo_count) / n2
        JSD += p1 * log(p1 / p2)  # p1 as reference
        JSD += p2 * log(p2 / p1)  # p2 as reference
    JSD /= 2

    print(JSD, end='')
