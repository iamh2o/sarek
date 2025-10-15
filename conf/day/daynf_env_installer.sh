#!/usr/bin/env bash

################################################################################
# Script Name: daynf_env_installer.sh
# Description: Sets up Miniconda and installs the DAYNF conda environment.
# Usage:       source ./daynf_env_installer.sh DAYNF
#              Provide 'DAYNF' as the argument to start the installation.
#              If the 'DAYNF' environment already exists, the script will prompt accordingly.
################################################################################


# Function to display usage information
usage() {
    echo "Usage: source $0 DAYNF"
    echo "This script installs Miniconda and sets up the DAYNF conda environment."
    echo "Provide 'DAYNF' as the argument to start the installation."
    return 2
}

# Check if the correct argument is provided
DY_ENVNAME="DAYNF"
if [[ "$1" != "$DY_ENVNAME" ]]; then
    echo "Hello! This is the __ $DY_ENVNAME __ installation script."
    echo ""
    echo "The DAYNF environment installs the software needed to trigger Snakemake and run the Day (dynf-) CLI."
    echo "To run and start the install, provide 'DAYNF' as the argument."
    echo ""
    echo "Usage: $0 DAYNF"
    echo ""
    echo "If you have an existing DAYNF install, you may need to remove it first:"
    echo "  conda env remove -n DAYNF"
    echo ""
    usage
fi

# Check if the shell is bash
if [[ "$SHELL" != "/bin/bash" ]]; then
    echo "Warning: This script is designed to work with bash."
    echo "Your current shell is $SHELL. Proceeding, but compatibility is not guaranteed."
    sleep 2
fi

# Set the script directory
SCRIPT_DIR=conf/day/
echo "Path to environment working directory is $SCRIPT_DIR"

# Create .parallel directory if it doesn't exist
mkdir -p "$HOME/.parallel"

# Function to install Miniconda
install_miniconda() {
    echo "No conda environment detected."
    echo "Installing Miniconda to $CONDA_DIR"

    wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/Miniconda3.sh
    bash /tmp/Miniconda3.sh -b -p "$CONDA_DIR"
    rm /tmp/Miniconda3.sh

    source "$CONDA_DIR/etc/profile.d/conda.sh"
    conda init bash
    source "$HOME/.bashrc"
    conda activate

    echo "Conda installation complete."
    
    echo "Adding repo tag pinning stuff"
    conda install -y -n base -c conda-forge yq || (echo 'Failed to install yq' && return 1)


}

# Detect or install conda
if command -v conda &> /dev/null; then
    CONDA_DIR="$(dirname "$(dirname "$(which conda)")")"
    echo "Conda detected at $CONDA_DIR"
else
    CONDA_DIR="$HOME/miniconda3"
    install_miniconda
fi

# Ensure conda is initialized
source "$CONDA_DIR/etc/profile.d/conda.sh"

#conda install -y conda=25.5.1

# Update Conda Config
conda config --add channels conda-forge
conda config --add channels bioconda

conda config --set channel_priority strict || echo 'Failed to set conda priority to strict'
conda config --set repodata_threads 10 || echo 'Failed to set repodata_threads'
conda config --set verify_threads 4 || echo 'Failed to set verify_threads'
conda config --set execute_threads 4 || echo 'Failed to set execute_threads'
conda config --set always_yes yes || echo 'Failed to set always_yes'
conda config --set default_threads 10 || echo 'Failed to set default_threads'
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r

# Check if the DAYNF environment already exists
if conda env list | grep -q "^$DY_ENVNAME\s"; then
    echo ""
    echo "It appears you have a DAYNF environment already."
    echo "You may need to manually remove the conda env dir for DAYNF and try again."
    echo "To remove the environment, run:"
    echo "  conda env remove -n DAYNF"
    return 0
else
    conda install -y -n base -c conda-forge yq || echo 'Failed to install yq'
    echo "Installing DAYNF environment..."
    # Create the DAYNF environment
    if conda env create -n "$DY_ENVNAME" -f "$SCRIPT_DIR/day.yaml"; then
        echo "DAYNF environment created successfully."
        echo ""
        echo "Try the following commands to get started:"
        echo "  source dyinit --project <PROJECT>"
        echo "  dynf-a local"
    else
        echo "Failed to create DAYNF environment."
        return 1
    fi
fi

echo ""
echo "Installation complete."
echo "Please log out and log back in, then run:"
echo "  source dyinit --project <PROJECT>"
echo "  dynf-a local"

return 0
