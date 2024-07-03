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
    n1 = sum(counts1.values())
    n2 = sum(counts2.values())

    jsd = 0
    for word in vocab:
        p1 = counts1.get(word, 0) / n1
        p2 = counts2.get(word, 0) / n2
        m = 0.5 * (p1 + p2)
        jsd += 0 if p1 == 0 else p1 * log(p1 / m)  # p1 as reference
        jsd += 0 if p2 == 0 else p2 * log(p2 / m)  # p2 as reference
    jsd /= 2

    print(jsd, end='')
