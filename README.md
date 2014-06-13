
[![Build Status](https://travis-ci.org/iracooke/protk.png?branch=master)](https://travis-ci.org/iracooke/protk)

# protk ( Proteomics toolkit )


***
## What is it?

Protk is a suite of tools for proteomics. It aims to present a simple and consistent command-line interface across otherwise disparate third party tools.  The following analysis tasks are currently supported; 

- Tandem MS search with X!Tandem, Mascot, OMSSA and MS-GF+
- Peptide and Protein inference with Peptide Prophet, iProphet and Protein Prophet
- Conversion of pepXML or protXML to tabulular format


## Installation
 
Protk is a ruby gem and requires ruby 2.0 or higher with support for libxml2. To avoid installation problems we recommend using [rvm](https://rvm.io) to install ruby.

``` shell
    gem install protk
```



## Usage

Protk consists of a suite of small ruby programs.  After installing the protk rubygem the following should be available for running in your shell.  Help can be obtained on using any program by typing its name without any arguments.  Note than many protk programs require third party tools to be installed, see [Configuration](#user-content-configuration) below for instructions on installing these.

- `tandem_search.rb` Run an X!Tandem search. Requires [X!Tandem](http://www.thegpm.org/TANDEM/)
- `mascot_search.rb` Run a Mascot search. Requires a [Mascot](http://www.matrixscience.com/server.html) server
- `msgfplus_search.rb` Run an MS-GF+ search. Requires [MS-GF+](https://bix-lab.ucsd.edu/pages/viewpage.action?pageId=13533355)
- `omssa_search.rb` Run an OMSSA search. Requires [OMSSA](ftp://ftp.ncbi.nih.gov/pub/lewisg/omssa/CURRENT/)
- `peptide_prophet.rb` Perform peptide inference based on search engine scores. Requires the [TPP](http://sourceforge.net/projects/sashimi/files/Trans-Proteomic%20Pipeline%20%28TPP%29/)
- `interprophet.rb` Perform peptide inference across multiple search engines. Requires the [TPP](http://sourceforge.net/projects/sashimi/files/Trans-Proteomic%20Pipeline%20%28TPP%29/)
- `protein_prophet.rb` Perform protein inference. Requires the [TPP](http://sourceforge.net/projects/sashimi/files/Trans-Proteomic%20Pipeline%20%28TPP%29/)
- `mascot_to_pepxml.rb` Convert raw mascot dat files to pepXML. Requires the [TPP](http://sourceforge.net/projects/sashimi/files/Trans-Proteomic%20Pipeline%20%28TPP%29/)
- `tandem_to_pepxml.rb` Convert raw X!Tandem outputs to pepXML. Requires the [TPP](http://sourceforge.net/projects/sashimi/files/Trans-Proteomic%20Pipeline%20%28TPP%29/)
- `pepxml_to_table.rb` Convert pepXML to tabular format
- `protxml_to_table.rb` Convert protXML to tabular format
- `make_decoy.rb` Generate semi-random decoy sequences
- `sixframe.rb` Generate six-frame translations of DNA sequences
- `protk_setup.rb` Install third party dependencies
- `manage_db.rb` Manage protein databases

## Configuration

Protk includes a setup tool to install various third party proteomics tools such as the TPP, OMSSA, MS-GF+, Proteowizard.  If this tool is used it installs everything under `.protk/tools`.  To perform such an installation use;

```shell
    protk_setup.rb tpp omssa blast msgfplus pwiz
```

By default protk will install tools and databases into `.protk` in your home directory.  If this is not desirable you can change the protk root default by setting the environment variable `PROTK_INSTALL_DIR`. If you prefer to install the tools yourself protk will find them provided they are included in your `$PATH`. Those executables will be used as a fallback if nothing is available under the `.protk` installation directory.


## Sequence databases

Protk also includes a script called manage_db.rb to install specific sequence databases for use by the search engines if desired. Databases installed via manage_db.rb can be invoked using a shorthand name rather than a full path to a fasta file, and Protk also provides some automation for database upgrades. Protk comes with several predefined database configurations. For example, to install a database consisting of human entries from Swissprot plus known contaminants use the following commands;

```sh
manage_db.rb add --predefined crap
manage_db.rb add --predefined sphuman
manage_db.rb update crap
manage_db.rb update sphuman
```

You should now be able to run database searches, specifying this database by using the -d sphuman flag.  Every month or so swissprot will release a new database version. You can keep your database up to date using the manage_db.rb update command. This will update the database only if any of its source files (or ftp release notes) have changed. The manage_db.rb tool also allows completely custom databases to be configured. Setup requires adding quite a few command-line options but once setup, databases can easily be updated without further config. The example below shows the commandline arguments required to manually configure the sphuman database.

```sh
manage_db.rb add --ftp-source 'ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/reldate.txt' --include-filters '/OS=Homo\ssapiens/' --id-regex 'sp\|.*\|(.*?)\s' --add-decoys --make-blast-index --archive-old sphuman
```

## Galaxy Integration

Many protk tools have equivalent galaxy wrappers available on the [galaxy toolshed](http://toolshed.g2.bx.psu.edu/) .  In order for these tools to work you will also need to make sure that protk, as well as the necessary third party dependencies are available to galaxy during tool execution. If you install protk using the default system ruby (without rvm) this will probably just work, however you will lose the ability to run specific versions of tools against specific versions of protk.  The recommended method of installing protk for use with galaxy is as follows;

1. Ensure you have a working install of galaxy. 

[Full instructions](https://wiki.galaxyproject.org/Admin/GetGalaxy) are available on the official Galaxy project wiki page.  We assume you have galaxy installed in a directory called galaxy-dist.

2. Install rvm if you haven't allready.  See [here](https://rvm.io/) for more information.

```bash
	curl -sSL https://get.rvm.io | bash -s stable
```

3. Install a compatible version of ruby using rvm. Ruby 2.0 or higher is required

```bash
	rvm install 2.1
```

4.  Install protk in an isolated gemset using rvm.

This sets up an isolated environment where only a specific version of protk is available.  We name the environment according to the protk version (1.2.6 in this example).

```bash
	rvm 2.1
	rvm gemset create protk1.2.6
	rvm use 2.1@protk1.2.6
	gem install protk -v 1.2.6
```

5. Configure Galaxy's tool dependency directory.

Create a directory for galaxy tool dependencies. This must be outside the galaxy-dist directory. I usually create a directory called tool_dependencies alongside galaxy-dist.
Open the file `universe_wsgi.ini` in the galaxy-dist directory and set the configuration option `tool_dependency_dir` to point to the directory you just created, eg;

```
	tool_dependency_dir = ../tool_dependencies
```

6.  Create a tool dependency that sets up protk in the environment created by rvm

In this example we create the environment for protk `1.2.6` as this was the version installed in step 4 above.

```bash
	cd <tool_dependency_dir>
	mkdir protk
	cd protk
	mkdir 1.2.6
	ln -s 1.2.6 default
	echo `rvm env --path 2.1@protk1.2.6` > 1.2.6/env.sh
```

7. Keep things up to date

When new versions of galaxy tools are released they may change the version of protk that is required.  Check the release notes on the tool to see what is needed.  For example, if upgrading to version 1.2.7 you would do the following;

```bash
	rvm 2.1
	rvm gemset create protk1.2.7
	rvm use 2.1@protk1.2.7
	gem install protk -v 1.2.7
	cd <tool_dependency_dir>/protk/
	mkdir 1.2.7
	echo `rvm env --path 2.1@protk1.2.7` > 1.2.7/env.sh
	ln -s 1.2.7 default
```


