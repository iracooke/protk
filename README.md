# protk ( Proteomics toolkit )


***
## Development Status

protk is still in development. Only some of the tools work. None of them should be relied upon for production use yet.

***

## Design Goals

The overall goal of protk is to provide;

* A consistent command-line interface for proteomics tools
* The ability to run tools in the background (via pbs)
* Automatic configuration of as many aspects of tool input as possible

***
## Dependencies

### *TPP* 
http://sourceforge.net/projects/sashimi/files/

### *OMSSA* 
http://pubchem.ncbi.nlm.nih.gov/omssa/linux.htm

### *Sequence Databases*

* Download and install fasta files for sequence databases you want to use. 
* For OMSSA you will need to install the ncbi tools to create databases in the correct format. 
* NCBI tools can be downloaded here ftp://ftp.ncbi.nih.gov/blast/executables/LATEST
* For each database fasta file run
runmakeblastdb -in mydbname.fasta -parse_seqids

### Ruby 
On Ubuntu

* sudo apt-get install ruby
* sudo apt-get install rubygems

### Gems
open4
rest-client
libxml-ruby
bio
spreadsheet
logger
