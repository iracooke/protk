# protk ( Proteomics toolkit )


***
## What is it?

Protk is a wrapper for various proteomics tools. Initially it focusses on MS/MS database search and validation but other tools will be added over time

## Why do we need a wrapper around these tools

The tools themselves typically have their own command-line interfaces, each of which is designed to accept different kinds of inputs.  The aim of protk is present an interface to each tool that is as uniform as possible with common options that work across tools. In addition, protk provides built-in support for submitting jobs to a cluster, and for management tasks such as database installation. 

***

## Installation

The hardest part about installing protk is likely to be installation of its dependencies, particularly the trans proteomic pipeline, which is large and complex.

To start the installation simply run the script "setup.sh".  This script will attempt to install all required ruby dependencies and will check for other required binaries. If you have the required binaries in your PATH a link will be created for each in ./bin .  If the requirement is missing, instructions will be displayed on how to install it.


### *Sequence Databases*

* Download and install fasta files for sequence databases you want to use. 
* For OMSSA you will need to install the ncbi tools to create databases in the correct format. 
* NCBI tools can be downloaded here ftp://ftp.ncbi.nih.gov/blast/executables/LATEST
* For each database fasta file run
runmakeblastdb -in mydbname.fasta -parse_seqids
