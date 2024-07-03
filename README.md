# Workflow Tutorial

## Background
This is the companion repo for a [tutorial](https://marcsingleton.github.io/posts/workflow-managers-in-data-science-nextflow-and-snakemake/) on workflow managers hosted on my blog. The overall idea is to demonstrate the use of two workflow managers commonly used in scientific computing, Nextflow and Snakemake, by automating a "pipeline" that doesn't require any special software or domain knowledge to use or understand. The purpose of the analysis is to determine if the words used in a set of books are more similar within genres than between genres. The input data, then, are 13 files obtained from [Project Gutenberg](https://www.gutenberg.org/), each containing a text of a book in the public domain. They are *very* loosely organized into three genres: children's literature, science fiction, and Shakespeare. The pipeline proceeds in four main steps. First, the input files are cleaned of Project Gutenberg specific headers and footers. Next, a word count distribution is calculated for each book. These distributions are then compared across all pairs of books using a metric called the Jensen-Shannon divergence, and afterwards the results are aggregated within and between genres.

## Use
The pipeline's major components are largely written in Python and use SciPy and pandas for statistical functions and manipulating tabular data, respectively. (The exact versions are detailed in `env.yaml`). Executing the workflow files requires working installations of [Nextflow](https://www.nextflow.io/docs/latest/index.html) and [Snakemake](https://snakemake.readthedocs.io/en/stable/index.html). The Snakemake workflow additionally depends on an inline Bash script that uses a few standard Unix command-line programs.

To run the Nextflow workflow, use:

```
nextflow run workflow.nf
```

To run the Snakemake workflow, use:

```
snakemake -c 1 -s workflow.smk
```
