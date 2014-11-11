# Steps to run a Proteogenomics analysis

## Step 1. Create a comprehensive database

For a transcriptome only project this would consist of full 6-frame translations of the assembled transcripts.  For a genome project it would most likely be a combination of predicted (spliced) transcripts from a gene prediction program like `Augustus`, 6-frame translations of the whole genome (if feasible), and 6-frame translations of assembled transcripts (if any).  Importantly, for each of these database components you must have `fasta` formatted amino acid sequences, as well as `gff3` formatted coordinates describing the coordinates of each amino-acid sequence in the database mapped to its genomic or transcriptomic origin (a contig, or assembled transcript).

`Protk` provides some scripts to assist with database creation. Run the `sixframe` script twice on nucleotide sequences to generate `fasta` and then `gff` output; 

```bash
	sixframe.rb transcriptome.fasta --min-len 10 > transcriptome6f.fasta
	sixframe.rb transcriptome.fasta --min-len 10 --gff > transcriptome6f.gff3
```

## Step 2. Run searches

Using the comprehensive database created in step 1, run tandem MS/MS searches.  The final result should be a `protXML` file.

## Step 3. Map peptides to nucleotides

Instead of blasting or other approximate sequence matching technique, protk uses precise genomic coordinate information encoded in a `gff` file to map peptides to nucleic acid sequence locations.  This is done using the `protxml_to_gff` script.