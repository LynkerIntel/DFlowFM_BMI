#! /bin/bash
 
# Usage:
#   - Modify this script where needed (e.g. number of nodes, number of tasks per node, Singularity version).
#   - Execute this script from the command line of H7 using:
#     sbatch ./submit_singularity_h7.sh
#
# This is an h7 specific script for single (or multi-node) simulations
 
 
#--- Specify Slurm SBATCH directives ------------------------------------------------------------------------
#SBATCH --nodes=1               # Number of nodes.
#SBATCH --ntasks-per-node=1     # The number of tasks to be invoked on each node.
                                # For sequential runs, the number of tasks should be '1'.
                                # Note: SLURM_NTASKS is equal to "--nodes" multiplied by "--ntasks-per-node".
#SBATCH --job-name=test_model   # Specify a name for the job allocation.
#SBATCH --time 01:00:00         # Set a limit on the total run time of the job allocation.
#SBATCH --partition=4vcpu       # Request a specific partition for the resource allocation.
                                # See: https://publicwiki.deltares.nl/display/Deltareken/Compute+nodes.
##SBATCH --exclusive            # The job allocation can not share nodes with other running jobs.
                                # In many cases this option can be omitted.
##SBATCH --contiguous           # The allocated nodes must form a contiguous set, i.e. next to each other.
                                # In many cases this option can be omitted.
 
#--- Load modules -------------------------------------------------------------------------------------------
module purge
module load apptainer/1.1.8     # Load the Singularity container system software.
module load intelmpi/2021.9.0   # Load the  message-passing library for parallel simulations.
 
 
#--- Setup the container ------------------------------------------------------------------------------------
# Delft3D FM Singularity containers are available on the P-drive here: P:\d-hydro\delft3dfm_containers\
# Specify the folder that contains the required version of the Singularity container
# Currently v2023.03 is supported.
containerFolder=/p/d-hydro/delft3dfm_containers/delft3dfm_2023.03
 
 
#--- Setup the model ----------------------------------------------------------------------------------------
# Specify the ROOT folder of your model, i.e. the folder that contains ALL of the input files and sub-folders, e.g:
modelFolder=/p/myFolder/singularity/delft3dfm/test


# Specify the folder containing your model's MDU file.
mdufileFolder=$modelFolder/dflowfm
 
# Specify the folder containing your DIMR configuration file.
dimrconfigFolder=$modelFolder
 
# The name of the DIMR configuration file. The default name is dimr_config.xml. This file must already exist!
dimrFile=dimr_config.xml
 
# Stop the computation after an error occurs.
set -e
 
# For parallel processes, the lines below update the <process> element in the DIMR configuration file.
# The updated list of numbered partitions is calculated from the user specified number of nodes and cores.
# You DO NOT need to modify the lines below.
PROCESSSTR="$(seq -s " " 0 $((SLURM_NTASKS-1)))"
sed -i "s/\(<process.*>\)[^<>]*\(<\/process.*\)/\1$PROCESSSTR\2/" $dimrconfigFolder/$dimrFile
 
# The name of the MDU file is read from the DIMR configuration file.
# You DO NOT need to modify the line below.
mduFile="$(sed -n 's/\r//; s/<inputFile>\(.*\).mdu<\/inputFile>/\1/p' $dimrconfigFolder/$dimrFile)".mdu
 
 
#--- Partition by calling the dflowfm executable -------------------------------------------------------------
if [ "$SLURM_NTASKS" -gt 1 ]; then 
    echo ""
    echo "Partitioning parallel model..."
    cd "$mdufileFolder"
    echo "Partitioning in folder ${PWD}"
    srun -n 1 -N 1 $containerFolder/execute_singularity_h7.sh -c $containerFolder -m $modelFolder dflowfm --nodisplay --autostartstop --partition:ndomains="$SLURM_NTASKS":icgsolver=6 "$mduFile"
else 
    #--- No partitioning ---
    echo ""
    echo "Sequential model..."
fi 
 
#--- Simulation by calling the dimr executable ----------------------------------------------------------------
echo ""
echo "Simulation..."
cd $dimrconfigFolder
echo "Computing in folder ${PWD}"
srun $containerFolder/execute_singularity_h7.sh -c $containerFolder -m $modelFolder dimr "$dimrFile"