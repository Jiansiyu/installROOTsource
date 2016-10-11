#!/bin/bash
# Author: Matthew Feickert <matthew.feickert@cern.ch>
# Date: 2016-10-11
# Description: Install ROOT 6 from source
#   Follows the ROOT build instructions <https://root.cern.ch/building-root>
#   but deviates as a result of RootTalk topic 20986
#   <https://root.cern.ch/phpBB3/viewtopic.php?f=3&t=20986&p=98902#p98926>
#   Tested on Ubuntu 16.04 LTS, gcc 5.4, with Anaconda

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
mkdir root; cd root

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
echo "use IDE project files or start the build from the build"
echo "directory"
echo "N.B.: This will take a long time. Now is a good time to"
echo "go for a coffee."
echo "#######################################################"
#cmake --build . >> cmake.out.txt 2>&1
make -j4 >> cmake.out.txt 2>&1

#echo ""
#echo "#######################################################"
#echo "Step 6: Set the make directory"
#echo "#######################################################"
#cmake -DCMAKE_INSTALL_PREFIX=$TLDIR/root -P cmake_install.cmake
#
#echo ""
#echo "#######################################################"
#echo "Step 7: After ROOT has finished building, install it"
#echo "from the build directory"
#echo "#######################################################"
#sudo cmake --build . --target install >> cmake.out.txt 2>&1

echo ""
echo "#######################################################"
#echo "Step 8: Setup the environment to run"
echo "Step 6: Setup the environment to run"
echo "#######################################################"
source bin/thisroot.sh
