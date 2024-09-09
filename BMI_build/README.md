# DFLOWFM_NOAA_BMI
DFLOWFM source code branch in Deltares Delft3D GitLab repository (https://git.deltares.nl/oss/delft3d/-/merge_requests/493) that has modified the model engine source code invasively to enable the model to comply with Basic Model Interface (BMI) standards. Currently, this code is not compatible to merge with Delft3D main branch until the EC-Module has been modified to dynamically bypass external forcing file requirements for boundary conditions and meteorological forcings while allowing some third party coupling framework update those arrays on the fly.

Author: Jason Ducker, Lynker Technologies LLC., Affiliate for Office of Water Prediction at NOAA

Current use of DFlowFM BMI: Integration of this coastal model as BMI formulation within the NOAA Office of Water Predicition within the Next Generation Water Resources Framework project.

# Requirements for compiling DFLOWFM Model Engine Version and BMI libraries
1. cmake >= 3.20
2. szip >= 2.1
3. intel >= 2018
4. impi >= 2018
5. netcdf >= 4.7.0
6. proj >= 7.1.0
7. gdal >= 3.5.0
8. petsc >= 3.19
9. metis >= 5.1

# DFlowFM Documentation and Model Setup
For infromation about DFlowFM model engine physics, file descriptions, and model setups for a given simulation; please refer to Deltares reference manual link below:
https://content.oss.deltares.nl/delft3d/D-Flow_FM_User_Manual.pdf


# Steps below to compile DFlowFM model source code along with BMI shared libraries
1. In the root directory of the DFlowFM source code, open the build.sh file. Go to lines 190-192 and change the following syntax to compile the DFLOWFM model engine source code only: config="dflowfm", generator="Unix Makefiles", compiler="intel21"
2. Go into "src" directory, and edit the "setenv.sh" file to essentially load and link your library paths that are required to compile DFlowFM source code as stated above. *** The current setenv.sh file is already set for the RDHPCS NOAA Hera cluster, so if you're compiling it on there you dont need to change it ***
3. Go back into the root directory and execute "./build.sh" to initiate the DFlowFM model to use cmake and build the entire model engine source code from scratch. If successful, you should see that all DFLOWFM model engine modules have been built in the newly created "build_dflowfm" directory.
4. The DFlowFM build has now also compiled and linked the DFlowFM BMI shared libraries and it's driver test for a baseline BMI simulation for a given user. You will see the shared libraries and the driver executbale being copied over to the $root/BMI_build directory for the user to utilize the model within a BMI coupling framework. 
5. The sample "namelist.input" file inside the $root/BMI_build directory serves as the BMI configuration file for DFlowFM that should be copied over to your model directory for testing along with the driver executable.

# DflowFM BMI code and driver directories inside model engine repository
1. BMI: $DFlowFM_root/src/engines_gpl/dflowfm/packages/dflowfm_bmi_lib/src
1. Driver: $DFlowFM_root/src/test/engines_gpl/dflowfm/packages/dflowfm_bmi2/src

# Current Limitations of DFlowFM BMI implementation & To Do Work
1. MPI Parallelization has not be implemented properly within the DFlowFM BMI.
2. Invasive source code modifications were made to bypass forcing file requirements from the EC-Module and initialize "t0" and "t1" fields for boundary conditions and meteorolgical forcings. This means that no other branch of DFlowFM source code is compatible to merge with this repository currently. This was a specialized "NOAA" BMI branch that is available in the Deltares GitLab repo, but not for any further development on the DFlowFM model engine.
3. Coupling inland discharge boundaries from the T-Route model requires DFlowFM BMI geospatial fields to utilize NextGen hydrofabric flowpath id integers "id" identifers within the FlowFM_bnd.ext file setup for either point-source inland discharge boundary blocks OR semi-circle polygon inland lateral discharge boundary blocks. 
4. No surface runoff contributions are currently integrated with the DFlowFM BMI here since they're not readily available at this stage for testing with the DFlowFM BMI development completed here. Instead, the current DFlowFM model setups just utilize the NextGen Forcings Engine rainfall fields as the sole component of lateral discharge contributions within a given domain. The main caveat to that method is ignoring contributions from snow melt runoff or ground water discharge overflow. Work will need to revise the DFlowFM BMI implementation to seperate out lateral discharge fields from semi-circle polygon inland discharge boundaries and surface runoff contributions, which has two distinct geospatial fields that will be needed to advertise to the NextGen framework. 
