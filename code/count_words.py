"""Count words in a file."""

import os
import re
from argparse import ArgumentParser
from collections import Counter
from operator import itemgetter
from string import punctuation


def process_line(line):
    words = re.split('[\s—]+', line)  # Whitespace and dashes
    return words


def process_word(word):
    word = word.strip(punctuation).lower()
    return word


punctuation = punctuation + '‘’“”'  # Add curly quotes

if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument('input_path')
    parser.add_argument('output_path')
    args = parser.parse_args()

    count = Counter()
    with open(args.input_path) as file:
        for line in file:
            words = [process_word(word) for word in process_line(line)]
            words = [word for word in words if word]
            count.update(words)

    output_dir = os.path.dirname(args.output_path)
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    with open(args.output_path, 'w') as file:
        file.write('word\tcount\n')
        for word, count in sorted(count.items(), key=itemgetter(1), reverse=True):
            file.write(f'{word}\t{count}\n')
