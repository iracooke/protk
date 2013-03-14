# protk ( Proteomics toolkit )


***
## What is it?

Protk is a wrapper for various proteomics tools. It aims to present a consistent interface to a wide variety of tools and provides support for managing protein databases. 

***



## Basic Installation
 
Protk depends on ruby 1.9.  The recommended way to install ruby and manage ruby gems is with rvm. Install rvm using this command.
    
```sh
curl -L https://get.rvm.io | bash -s stable
```

Next install ruby and protk's dependencies

On OSX

```sh
rvm install 1.9.3 --with-gcc=clang
rvm use 1.9.3
gem install protk
protk_setup.rb package_manager
protk_setup.rb system_packages
protk_setup.rb all
```
On Linux

```sh    
rvm install 1.9.3
rvm use 1.9.3
gem install protk
sudo protk_setup.rb system_packages
protk_setup all
```

## Sequence databases

After running the setup.sh script you should run manage_db.rb to install specific sequence databases for use by the search engines. Protk comes with several predefined database configurations. For example, to install a database consisting of human entries from Swissprot plus known contaminants use the following commands;

```sh
manage_db.rb add crap
manage_db.rb add sphuman
manage_db.rb update crap
manage_db.rb update sphuman
```

You should now be able to run database searches, specifying this database by using the -d sphuman flag.  Every month or so swissprot will release a new database version. You can keep your database up to date using the manage_db.rb update command. This will update the database only if any of its source files (or ftp release notes) have changed. The manage_db.rb tool also allows completely custom databases to be configured. Setup requires adding quite a few command-line options but once setup, databases can easily be updated without further config. The example below shows the commandline arguments required to manually configure the sphuman database.

```sh
manage_db.rb add --ftp-source 'ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/reldate.txt' --include-filters '/OS=Homo\ssapiens/' --id-regex 'sp\|.*\|(.*?)\s' --add-decoys --make-blast-index --archive-old sphuman
```

## Galaxy integration

Although all the protk tools can be run directly from the command-line a nicer way to run them (and visualise outputs) is to use the galaxy web application.

1. Check out and install the latest stable galaxy [see the official galaxy wiki for more detailed setup instructions](http://wiki.g2.bx.psu.edu/Admin/Get%20Galaxy,"galaxy wiki")

```sh
hg clone https://bitbucket.org/galaxy/galaxy-dist 
cd galaxy-dist
sh run.sh
```

2. Make the protk tools available to galaxy. 
    - Create a directory for galaxy tool dependencies. It's best if this directory is outside the galaxy-dist directory. I usually create a directory called `tool_depends` alongside `galaxy-dist`.
    - Open the file `universe_wsgi.ini` in the `galaxy-dist` directory and set the configuration option `tool_dependency_dir` to point to the directory you just created
    - Create a protkgem directory inside `<tool_dependency_dir>`. 

            cd <tool_dependency_dir>
            mkdir protkgem
			cd protkgem
            mkdir rvm193
            ln -s rvm193 default
            cd default
            ln -s ~/.protk/galaxy/env.sh env.sh

3. Install any of the Proteomics tools that depend on protk from the galaxy toolshed

4. After installing the protk wrapper tools from the toolshed it will be necessary to tell those tools about databases you have installed. Use the manage_db.rb tool to do this. 



