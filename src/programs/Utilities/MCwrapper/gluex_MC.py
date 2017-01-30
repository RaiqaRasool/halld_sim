#!/usr/bin/env python
##########################################################################################################################
#
# 2017/01 Thomas Britton
# Heavily based off of work by Paul Mattione
#
# NOTE: THERE ARE GLOBAL VARIABLES BELOW THAT SHOULD BE MODIFIED BEFORE RUNNING
#
#
#   Options:
#      MC variation can be changed by supplying "variation=xxxxx" option otherwise default: mc
#      the number of events to be generated per file (except for any remainder) can be set by "per_file=xxxx" default: 1000
#
#      If the user does not want genr8, geant, smearing, reconstruction to be performed the sequence will be terminated at the first instance of genr8=0,geant=0,mcsmear=0,recon=0 default: all on
#      Similarly, if the user wishes to retain the files created by any step you can supply the cleangenr8=0, cleangeant=0, cleanmcsmear=0, or cleanrecon=0 options.  By default all but the reconstruction files #      are cleaned. 
#
#      The reconstruction step is multi-threaded, for this step, if enabled, the script will use 4 threads.  This threading can be changed with the "numthreads=xxx" option 
#
#      By default the job will run interactively in the local directory.  If the user wishes to submit the jobs to swif the option "swif=1" must be supplied.
#
# SWIF DOCUMENTATION:
# https://scicomp.jlab.org/docs/swif
# https://scicomp.jlab.org/docs/swif-cli
# https://scicomp.jlab.org/help/swif/add-job.txt #consider phase!
#
##########################################################################################################################

from optparse import OptionParser
import os.path
import os
import sys
import re
import subprocess
from subprocess import call
import glob


#################################################### GLOBAL VARIABLES ####################################################

# DEBUG
VERBOSE    = False

# PROJECT INFO
PROJECT    = "gluex"          # http://scicomp.jlab.org/scicomp/#/projects
TRACK      = "debug"		   # https://scicomp.jlab.org/docs/batch_job_tracks

# RESOURCES for swif jobs
NCORES     = "8"               # Number of CPU cores
DISK       = "10GB"            # Max Disk usage
RAM        = "20GB"            # Max RAM usage
TIMELIMIT  = "300minutes"      # Max walltime
OS         = "centos65"        # Specify CentOS65 machines


# OUTPUT DATA LOCATION
DATA_OUTPUT_BASE_DIR    = ""#your desired output location (only needed for SWIF jobs
#environment file location
ENVFILE           = "master_env_setup"#change this to your own environment location/file

def add_job(WORKFLOW,CHANNEL, RUNNO, FILENO,SCRIPT,COMMAND):

	# PREPARE NAMES
	STUBNAME = str(RUNNO) + "_" + str(FILENO)
	JOBNAME = WORKFLOW + "_" + STUBNAME

	# CREATE ADD-JOB COMMAND
	# job
	add_command = "swif add-job -workflow " + WORKFLOW + " -name " + JOBNAME
	# project/track
	add_command += " -project " + PROJECT + " -track " + TRACK
	# resources
	add_command += " -cores " + NCORES + " -disk " + DISK + " -ram " + RAM + " -time " + TIMELIMIT + " -os " + OS
	# stdout
	add_command += " -stdout " + DATA_OUTPUT_BASE_DIR + "/log/" + str(RUNNO) + "_stdout." + STUBNAME + ".out"
	# stderr
	add_command += " -stderr " + DATA_OUTPUT_BASE_DIR + "/log/" + str(RUNNO) + "_stderr." + STUBNAME + ".err"
	# tags
	add_command += " -tag run_number " + str(RUNNO)
	# tags
	add_command += " -tag file_number " + str(FILENO)
	# script with options command
	add_command += " "+SCRIPT  +" "+ COMMAND

	if(VERBOSE == True):
		print "job add command is \n" + str(add_command)

	# ADD JOB
	status = subprocess.call(add_command.split(" "))
		

########################################################## MAIN ##########################################################
	
def main(argv):
	parser_usage = "swif_gluex_MC.py workflow channel Run_Number num_events [all other options]"
	parser = OptionParser(usage = parser_usage)
	(options, args) = parser.parse_args(argv)


	#check if there are enough arguments
	if(len(argv)<4):
		parser.print_help()
		return

	#check if the needed arguments are valid
	if len(args[0].split("="))>1 or len(args[1].split("="))>1 or len(args[2].split("="))>1:
		parser.print_help()
		return
	#load all argument passed in and set default options
	WORKFLOW = args[0]
	CHANNEL = args[1]	
	RUNNUM = int(args[2])
	EVTS = int(args[3])

	VERSION  = "mc"
	PERFILE=1000
	GENR=1
	GEANT=1
	SMEAR=1
	RECON=1
	CLEANGENR=1
	CLEANGEANT=1
	CLEANSMEAR=1
	CLEANRECON=0
	MCSWIF=0
	NUMTHREADS=4

	#loop over arguments
	for argu in args:
		argfound=0
		flag=argu.split("=")
		#redundat check to jump over the first 4 arguments
		if(len(flag)<2):
			continue
		else:#toggle the flags as user defines
			if flag[0]=="variation":
				argfound=1
				VERSION=flag[1]
			if flag[0]=="per_file":
				argfound=1
				PERFILE=int(flag[1])
			if flag[0]=="genr8":
				argfound=1
				GENR=int(flag[1])
			if flag[0]=="geant":
				argfound=1
				GEANT=int(flag[1])
			if flag[0]=="mcsmear":
				argfound=1
				SMEAR=int(flag[1])
			if flag[0]=="recon":
				argfound=1
				RECON=int(flag[1])
			if flag[0]=="cleangenr8":
				argfound=1
				CLEANGENR=int(flag[1])
			if flag[0]=="cleangeant":
				argfound=1
				CLEANGEANT=int(flag[1])
			if flag[0]=="cleanmcsmear":
				argfound=1
				CLEANSMEAR=int(flag[1])
			if flag[0]=="cleanrecon":
				argfound=1
				CLEANRECON=int(flag[1])
			if flag[0]=="swif":
				argfound=1
				MCSWIF=int(flag[1])
			if flag[0]=="numthreads":
				argfound=1
				NUMTHREADS=int(flag[1])
			if argfound==0:
				print "WARNING OPTION: "+argu+" NOT FOUND!"
	

	#print a line indicating SWIF or Local run
	if MCSWIF != 1:
		print "Locally simulating "+args[2]+" "+CHANNEL+" Events"
	else:
		print "Creating "+WORKFLOW+" to simulate "+args[2]+" "+CHANNEL+" Events"
	# CREATE WORKFLOW
		status = subprocess.call(["swif", "create", "-workflow", WORKFLOW])

	#calculate files needed to gen
	FILES_TO_GEN=EVTS/PERFILE
	REMAINING_GEN=EVTS%PERFILE

	indir=os.getcwd()
	outdir=DATA_OUTPUT_BASE_DIR
	#if local run set out directory to cwd
	if MCSWIF==0:
		outdir="./"	

	#for every needed file call the script with the right options
	for FILENUM in range(1, FILES_TO_GEN + 2):
		num=PERFILE
		#last file gets the remainder
		if FILENUM == FILES_TO_GEN +1:
			num=REMAINING_GEN
		#if ever asked to generate 0 events....just don't
		if num == 0:
			continue

		COMMAND=ENVFILE+" "+CHANNEL+" "+str(indir)+" "+str(outdir)+" "+str(RUNNUM)+" "+str(FILENUM)+" "+str(num)+" "+str(VERSION)+" "+str(GENR)+" "+str(GEANT)+" "+str(SMEAR)+" "+str(RECON)+" "+str(CLEANGENR)+" "+str(CLEANGEANT)+" "+str(CLEANSMEAR)+" "+str(CLEANRECON)+" "+str(MCSWIF)+" "+str(NUMTHREADS)
		#print COMMAND
		#either call script.sh or add a job depending on swif flag
		if MCSWIF == 0:
			os.system("./script.sh "+COMMAND)
		else:
			add_job(WORKFLOW, CHANNEL, RUNNUM, FILENUM,str(os.getcwd())+"/script.sh",COMMAND)

if __name__ == "__main__":
   main(sys.argv[1:])

