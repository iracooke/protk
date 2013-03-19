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
sudo ~/.rvm/bin/rvm 1.9.3 do protk_setup.rb system_packages
protk_setup all
```

Instead off using protk_setup.rb all it might be preferable to only install some of the protk tool dependencies.  'all' is just an alias for the following full target list, any of which can be omitted with the consequence that tools depending on that component will not be available.  

```sh
protk_setup.rb tpp omssa blast msgfplus pwiz openms galaxyenv
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

The preferred method for use of protk with galaxy is to install via the [galaxy toolshed](http://toolshed.g2.bx.psu.edu).  You can find protk tools under the Proteomics heading.  You will still need to install and setup galaxy itself (step 1 below) and you should familiarise yourself with the admin functions of galaxy including tool installation.  Lots of instructions on this are available on the [toolshed wiki](http://wiki.galaxyproject.org/Tool%20Shed).  One final note is that although protk based tools are configured to automatically install their dependencies via the toolshed you should take careful note of the system packages that must be installed before proceeding.  In addition it is also a good idea to install low-level tools (eg the galaxy_protk repository) before installing dependent tools (eg TPP Prophets).

1. Check out and install the latest stable galaxy [see the official galaxy wiki for more detailed setup instructions](http://wiki.g2.bx.psu.edu/Admin/Get%20Galaxy,"galaxy wiki")

    ```sh
    hg clone https://bitbucket.org/galaxy/galaxy-dist 
    cd galaxy-dist
    sh run.sh
    ```


2. Make the protk tools available to galaxy. (Legacy. This step is not needed when installing via the toolshed)

    - Create a directory for galaxy tool dependencies. It's best if this directory is outside the galaxy-dist directory. I usually create a directory called `tool_depends` alongside `galaxy-dist`.
    - Open the file `universe_wsgi.ini` in the `galaxy-dist` directory and set the configuration option `tool_dependency_dir` to point to the directory you just created
    - Create a protkgem directory inside `<tool_dependency_dir>`. 

        ```sh
        cd <tool_dependency_dir>
        mkdir protkgem
		cd protkgem
        mkdir rvm193
        ln -s rvm193 default
        cd default
        ln -s ~/.protk/galaxy/env.sh env.sh
        ```

3. After installing the protk wrapper tools from the toolshed it will be necessary to tell those tools about databases you have installed. Use the manage_db.rb tool to do this.  In particular the manage_db.rb tool has a -G option to automatically tell galaxy about the location of its databases.  To use this though you will need to tell protk about the location of your galaxy install.  To do this
    - Create a file named `config.yml` inside your .protk directory
    - Add the line `galaxy_root: /home/galaxy/galaxy-dist` to config.yml substituting the actual path to the root directory of your galaxy installation

        ```sh 
        echo 'galaxy_root: /home/galaxy/galaxy-dist' > ~/.protk/config.yml
        ```


