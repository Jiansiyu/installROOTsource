#!/bin/bash
# Author: Matthew Feickert <matthew.feickert@cern.ch>
# Date: 2016-10-12
# Description: Install ROOT 6 from source using CMake
#   Follows the ROOT build instructions <https://root.cern.ch/building-root>
#   Tested on Ubuntu 16.04 LTS, gcc 5.4, with Anaconda

# Resource use warning
echo ""
echo "#######################################################"
echo "N.B.: To try and make this installation as quick as"
echo "possible a large amount of your computer's resources will"
echo "be used. It is advised that you don't run large programs"
echo "and close down any browsers that have many tabs open"
echo "before continuing with this installation to avoid crashes."
echo "#######################################################"
echo ""

# Select the home directory as the top level directory
TLDIR=~/
echo "ROOT will be installed in your home directory: $TLDIR"
read -r -p "Do you want ROOT installed in a DIFFERENT directory? [Y/n] " response
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
sudo apt-get install git dpkg-dev cmake g++ gcc binutils \
libx11-dev libxpm-dev libxft-dev libxext-dev

# Check that all optional packages are installed
sudo apt-get install gfortran libssl-dev libpcre3-dev \
libglu1-mesa-dev libglew-dev libftgl-dev \
libmysqlclient-dev libfftw3-dev libcfitsio-dev \
graphviz-dev libavahi-compat-libdnssd-dev \
libldap2-dev python-dev libxml2-dev libkrb5-dev \
libgsl-dev libqt4-dev ccache

cd "$TLDIR"
echo ""
echo "#######################################################"
echo "Step 1: Clone down the HTTP repository from SourceForge"
echo "#######################################################"
git clone http://root.cern.ch/git/root.git root_source

echo ""
echo "#######################################################"
echo "Step 2: Create and navigate to the build directory for"
echo "containing the build"
echo "#######################################################"
mkdir root_build; cd root_build

echo ""
echo "#######################################################"
echo "Step 3: unset the ROOTSYS ENV variable"
echo "#######################################################"
unset ROOTSYS

echo ""
echo "#######################################################"
echo "Step 4: Execute the cmake command with the path to the"
echo "top of your ROOT source tree"
echo "#######################################################"
##cmake -Dall="ON" -Dsoversion="ON" ../root_source >> cmake.out.txt 2>&1
cmake -Dall="ON" -Dsoversion="ON" -Dqtgsi="OFF" ../root_source >> cmake.out.txt 2>&1

echo ""
echo "#######################################################"
echo "Step 5: After CMake has finished running, proceed to"
echo "start the build from the build directory"
echo "N.B.: This will take a long time. Now is a good time to"
echo "go for a coffee."
echo "(To view progress do: tail -F root_build/cmake.out.txt)"
echo "#######################################################"
#cmake --build . -- -j4 --target install >> cmake.out.txt 2>&1
cmake --build . -- -j4 >> cmake.out.txt 2>&1

#echo ""
#echo "#######################################################"
#echo "Step 6: Setting the installation directory specified"
#echo "#######################################################"
#cmake -DCMAKE_INSTALL_PREFIX=$TLDIR/root_build -P cmake_install.cmake >> cmake.out.txt 2>&1
#
#echo ""
#echo "#######################################################"
#echo "Step 7: After ROOT has finished building, install it"
#echo "from the build directory"
#echo "#######################################################"
#cmake --build . --target install >> cmake.out.txt 2>&1

echo ""
echo "#######################################################"
#echo "Step 8: Setup the environment to run"
echo "Step 6: Setup the environment to run"
echo "From where you installed root do:"
echo "source bin/thisroot.sh"
echo "To test then run: which root"
echo "To setup root at launch of shell add to your"
echo "bash_profile:"
echo "source <output of which root>/bin/thisroot.sh"
echo "#######################################################"
