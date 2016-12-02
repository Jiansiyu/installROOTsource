#!/bin/bash
# Author: Matthew Feickert <matthew.feickert@cern.ch>
# Date: 2016-12-02
# Description: Install ROOT 6 from source using CMake
#   Follows the ROOT build instructions <https://root.cern.ch/building-root>
#   Tested on Ubuntu 16.04 LTS, gcc 5.4, with Anaconda
#   Testing on SL6 6.8, gcc 4.4.7, with Anaconda

# check that OS is supported
if [[ -f /etc/lsb-release ]]; then
    DIST=$(lsb_release -si)
    if [[ "$DIST" == "Ubuntu" ]]; then
        echo ""
    elif [[ "$DIST" == "Scientific" ]]; then
        echo ""
    else
    echo "You are not running SL or Ubuntu."
    echo "Sorry, you're OS is not supported at this time."
    exit
    fi
else
    echo "You are not running an lsb-release."
    echo "Sorry, you're OS is not supported at this time."
    exit
fi

# Resource use warning
echo ""
echo "#######################################################"
echo "N.B.: To try and make this installation as quick as"
echo "possible a large amount of your computer's resources"
echo "will be used. It is advised that you don't run large"
echo "programs and close down any browsers that have many"
echo "tabs open before continuing with this installation to"
echo "avoid crashes."
echo "#######################################################"
echo ""

# Select the home directory as the top level directory
TLDIR=~/
echo "ROOT will be built in your home directory: $TLDIR"
read -r -p "Do you want ROOT built in a DIFFERENT directory? [Y/n] " response
response=${response,,}    # tolower
if [[ $response =~ ^(yes|y)$ ]]; then
# Check if path is empty string
    read -r -e -p "Enter the full file path of the directory:" TLDIR
    if [[ -z "$TLDIR" ]]; then
        echo "That path you have entered is an empty string."
        exit
    fi
# Check if path does not exist
    if [[ ! -e "$TLDIR" ]]; then
        echo "The path does not exist."
        exit
    fi
fi

echo ""
# Default the install directory to be the build directory
INSTALLDIR="$TLDIR"
echo "ROOT will be installed in your build directory: $INSTALLDIR"
read -r -p "Do you want ROOT installed in a DIFFERENT directory? [Y/n] " response
response=${response,,}    # tolower
if [[ $response =~ ^(yes|y)$ ]]; then
# Check if path is empty string
    read -r -e -p "Enter the full file path of the directory:" INSTALLDIR
    if [[ -z "$INSTALLDIR" ]]; then
        echo "That path you have entered is an empty string."
        exit
    fi
# Check if path does not exist
    if [[ ! -e "$INSTALLDIR" ]]; then
        echo "The path does not exist."
        read -r -p "Would you like to make it? [Y/n] " response
        response=${response,,}    # tolower
        if [[ $response =~ ^(yes|y)$ ]]; then
            sudo mkdir "$INSTALLDIR"
        fi
        if [[ $response =~ ^(no|n)$ ]]; then
            exit
        fi
    fi
    INSTALLDIR="$INSTALLDIR"/root
    if [[ ! -e "$INSTALLDIR" ]]; then
        echo "Need sudo to make $INSTALLDIR"
        sudo mkdir "$INSTALLDIR"
    fi
fi

echo ""
echo "#######################################################"
echo "ROOT will be built in: $TLDIR"
echo "ROOT will be installed in: $INSTALLDIR"
echo "#######################################################"
echo ""

read -r -p "Is this all okay? [Y/n] " response
response=${response,,}    # tolower
if [[ $response =~ ^(no|n)$ ]]; then
    exit
fi
echo "Beginning installation!"

# Check that pacakges are installed for the correct OS
## Ubuntu
if [[ "$DIST" == "Ubuntu" ]]; then
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

## Scientific Linux
elif [[ "$DIST" == "Scientific" ]]; then
# Check that all required packages are installed
sudo yum install git cmake gcc-c++ gcc binutils \
libX11-devel libXpm-devel libXft-devel libXext-devel

# Check that all optional packages are installed
sudo yum install gcc-gfortran openssl-devel pcre-devel \
mesa-libGL-devel mesa-libGLU-devel glew-devel ftgl-devel mysql-devel \
fftw-devel cfitsio-devel graphviz-devel \
avahi-compat-libdns_sd-devel libldap-dev python-devel \
libxml2-devel gsl-static
fi

cd "$TLDIR"
echo ""
echo "#######################################################"
echo "Step 1: Clone the master branch of the Git repository"
echo "from CERN"
echo "#######################################################"
echo "git clone http://root.cern.ch/git/root.git root_src"
git clone http://root.cern.ch/git/root.git root_src

echo ""
echo "#######################################################"
echo "Step 2: Create and navigate to the build directory for"
echo "containing the build"
echo "#######################################################"
echo "mkdir root_build; cd root_build"
mkdir root_build; cd root_build

echo ""
echo "#######################################################"
echo "Step 3: unset the ROOTSYS ENV variable"
echo "#######################################################"
echo "unset ROOTSYS"
unset ROOTSYS

echo ""
echo "#######################################################"
echo "Step 4: Execute the cmake command with the path to the"
echo "top of your ROOT source tree"
echo "#######################################################"
echo "cmake -Dall=\"ON\" -Dsoversion=\"ON\" -Dqtgsi=\"OFF\" ../root_src"
##cmake -Dall="ON" -Dsoversion="ON" ../root_src >> cmake.out.txt 2>&1
cmake -Dall="ON" -Dsoversion="ON" -Dqtgsi="OFF" ../root_src >> cmake.out.txt 2>&1

echo ""
echo "#######################################################"
echo "Step 5: After CMake has finished running, proceed to"
echo "start the build from the build directory"
echo "N.B.: This will take a long time. Now is a good time to"
echo "go for a coffee."
echo "(To view progress do: tail -F root_build/cmake.out.txt)"
echo "#######################################################"
echo "cmake --build . -- -j4"
#cmake --build . -- -j4 --target install >> cmake.out.txt 2>&1
cmake --build . -- -j4 >> cmake.out.txt 2>&1

echo ""
echo "#######################################################"
echo "Step 6: Setting up the installation directory specified"
echo "(To view progress do:"
echo "tail -F root_build/cmake_install.out.txt)"
echo "#######################################################"
echo "sudo cmake -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} -P cmake_install.cmake"
sudo cmake -DCMAKE_INSTALL_PREFIX=$INSTALLDIR -P cmake_install.cmake >> cmake_install.out.txt 2>&1

#echo ""
#echo "#######################################################"
#echo "Step 7: Install ROOT with CMake"
#echo "#######################################################"
#cmake --build . --target install >> cmake_install.out.txt 2>&1

echo ""
echo "#######################################################"
#echo "Step 8: Setup the environment to run"
echo "Step 7: Setup the environment to run"
echo "From where you installed root (${INSTALLDIR}/) do:"
echo "source bin/thisroot.sh"
echo "To test then run: which root"
echo "To setup root at launch of shell add to your"
echo "bash_profile:"
echo "source <output of which root>/bin/thisroot.sh"
echo "#######################################################"
