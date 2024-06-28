"""Remove Project Gutenberg header and footer from file."""

import os
from argparse import ArgumentParser


def get_text_lines(path):
    with open(path) as file:
        in_text = False
        for line in file:
            if line.startswith('*** START OF THE PROJECT GUTENBERG EBOOK'):
                in_text = True
                continue  # Skip current line so it's not yielded
            if line.startswith('*** END OF THE PROJECT GUTENBERG EBOOK'):
                return
            if in_text:
                yield line

            
if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument('input_path')
    parser.add_argument('output_path')
    args = parser.parse_args()

    output_dir = os.path.dirname(args.output_path)
    if output_dir and not os.path.exists(output_dir):
        os.makedirs(output_dir)

    with open(args.output_path, 'w') as file:
        lines = get_text_lines(args.input_path)
        file.writelines(lines)

