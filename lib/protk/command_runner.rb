#
# This file is part of protk
# Created by Ira Cooke 15/12/2010
#
# Runs system commands and provides methods for monitoring output
#


require 'open4'
require 'protk/constants'

class CommandRunner  
  
  # The protk environment in which to run commands
  #
  attr :env
  
  
  
  
  def initialize(environment)
    @env=environment
  end
  
  
  
  
  # Runs the given command in a local shell
  #
  def run_local(command_string)
    @env.log("Command: #{command_string} started",:info)
    status = Open4::popen4("#{command_string} ") do |pid, stdin, stdout, stderr|
      puts "PID #{pid}" 
      
      stdout.each { |line| @env.log(line.chomp,:info) }

      stderr.each { |line| @env.log(line.chomp,:warn) }

    end
    if ( status!=0 )
      # We terminated with some error code so log as an error
      @env.log( "Command: #{command_string} exited with status #{status.to_s}",:error)
    else
      @env.log( "Command: #{command_string} exited with status #{status.to_s}",:info)      
    end
    status     
  end
  
  
  
  
  # Runs the given command as a background job
  # At present this sends the job to a PBS system, but in future we might support other types of background jobs
  #
  def run_batch(command_string,job_params,jobscript_path,autodelete)
    @env.log("Creating batch file for command: #{command_string}",:info)

    if ( autodelete )
  #    command_string<<";rm #{jobscript_path}"
    end

    jobid=job_params[:jobid]
    if ( job_params[:vmem]==nil)
      job_params[:vmem]="900mb"
    end
    if (job_params[:queue] ==nil )
      job_params[:queue]="lowmem"
    end

    job_script="#!/bin/bash
    #PBS -N #{jobid}
    #PBS -e pbs.#{jobid}.err 
    #PBS -o pbs.#{jobid}.log
    #PBS -l nodes=1:ppn=1,vmem=#{job_params[:vmem]}
    #PBS -q #{job_params[:queue]}
    #{command_string}"

    p File.open(jobscript_path, 'w') {|f| f.write(job_script) }

    self.run_local("qsub #{jobscript_path}")
    
  end
  
end