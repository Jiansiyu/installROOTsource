#!/bin/bash
# Author: Matthew Feickert (mfeickert@smu.edu)
# Date: 2016-02-01
# Description: Install ROOT 6 from source

# Select the home directory as the top level directory
TLDIR=~/
echo "ROOT will be installed in your home directory: $TLDIR"
read -r -p "Do you want ROOT installed in a different directory? [Y/n] " response
response=${response,,}    # tolower
if [[ $response =~ ^(yes|y)$ ]]; then
# Check if path is empty string
    read -r -e -p "Enter the full file path of the directory:" TLDIR
    if [ -z "$TLDIR" ]; then
        echo "That path you have entered is an empty string."
        exit
    fi
# Check if path does not exist
    if [ ! -e "$TLDIR" ]; then
        echo "The path does not exist."
        exit
    fi
fi
echo "ROOT will be installed in: $TLDIR"

# Check that all required packages are installed
sudo apt-get install git make gcc-c++ gcc binutils \
  libX11-devel libXpm-devel libXft-devel libXext-devel

# Check that all optional packages are installed
sudo apt-get install gcc-gfortran openssl-devel pcre-devel \
  mesa-libGL-devel mesa-libGLU-devel glew-devel ftgl-devel mysql-devel \
  fftw-devel cfitsio-devel graphviz-devel \
  avahi-compat-libdns_sd-devel libldap-dev python-devel \
  libxml2-devel gsl-static

cd "$TLDIR"
#Clone the HTTP repository
git clone http://root.cern.ch/git/root.git root_source
#Create and navigate to the build directory for containing the build
mkdir root; cd root
#unset the ROOTSYS ENV variable
unset ROOTSYS
#Execute the cmake command the path to the top of your ROOT source tree
cmake -Dall="ON" -Dsoversion="ON" ../root_source >> cmake.out.txt 2>&1
#After CMake has finished running, proceed to use IDE project files or start the build from the build directory
cmake --build . >> cmake.out.txt 2>&1
#Set the make directory
cmake -DCMAKE_INSTALL_PREFIX=~/root -P cmake_install.cmake
#After ROOT has finished building, install it from the build directory
sudo cmake --build . --target install >> cmake.out.txt 2>&1
#Setup the environment to run
source bin/thisroot.sh
