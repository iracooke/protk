# protk ( Proteomics toolkit )


***
## What is it?

Protk is a wrapper for various proteomics tools. Initially it focusses on MS/MS database search and validation but other tools will be added over time

## Why do we need a wrapper around these tools

The tools themselves typically have their own command-line interfaces, each of which is designed to accept different kinds of inputs.  The aim of protk is present an interface to each tool that is as uniform as possible with common options that work across tools. In addition, protk provides built-in support for submitting jobs to a cluster, and for management tasks such as database installation. 

***



## Installation
The following instructions have been tested on a clean installation of Ubuntu (ubuntu-11.10 64 bit)

To start installing run the setup script
    ./setup.sh

This script will attempt to install all required ruby dependencies and will check for other required binaries. If you have the required binaries in your PATH a link will be created for each in ./bin .  If the requirement is missing, instructions will be displayed on how to install it.


## Sequence databases

After running the setup.sh script you should run manage_db.rb to install specific sequence databases for use by the search engines. For example

    manage_db.rb -h
    manage_db.rb add -h #Get help on adding a database
    # Add a swissprot human database
    manage_db.rb add --ftp-source 'ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/reldate.txt' --include-filters '/OS=Homo\ssapiens/' --id-regex 'sp\|.*\|(.*?)\s' --add-decoys --make-blast-index --update-spec --archive-old sphuman

