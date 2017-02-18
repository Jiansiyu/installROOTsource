#!/bin/bash
# Author: Matthew Feickert <matthew.feickert@cern.ch>
# Date: 2017-02-01
# Description: Install ROOT 6 from source using CMake
#   Follows the ROOT build instructions <https://root.cern.ch/building-root>
#   Tested on Ubuntu 16.04 LTS, gcc 5.4, with Anaconda
#   Testing on SL6 6.8, gcc 4.4.7, with Anaconda

function getUserShell () {
    USERSHELL="$(echo $SHELL | sed 's:.*/::')"
}

function checkOS () {
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
}

function checkPackages () {
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
}

function setInstallLocation () {
    # c.f.: http://stackoverflow.com/questions/226703/how-do-i-prompt-for-yes-no-cancel-input-in-a-linux-shell-script
    # Select the home directory as the top level directory
    TLDIR=~/
    while true; do
    echo "ROOT will be built in your home directory: $TLDIR"
    read -p "Do you want ROOT built in a DIFFERENT directory? [Y/n] " yn
        case $yn in
            [Yy]* )
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
                fi; break;;
            [Nn]* ) break;;
            * )
                echo ""
                echo "Please answer Yes or No."
                echo "";;
        esac
    done

    echo ""
    # Default the install directory to be the build directory
    # TODO: For rebuild detect that 'which root' doesn't return null and start there
    INSTALLDIR="$TLDIR"
    while true; do
    echo "ROOT will be installed in your build directory: $INSTALLDIR"
    read -p "Do you want ROOT installed in a DIFFERENT directory? [Y/n] " yn
        case $yn in
            [Yy]* )
            # Check if path is empty string
            read -r -e -p "Enter the full file path of the directory:" INSTALLDIR
            if [[ -z "$INSTALLDIR" ]]; then
                echo "That path you have entered is an empty string."
                exit
            fi
            # Check if path does not exist
            if [[ ! -e "$INSTALLDIR" ]]; then
                while true; do
                echo "The path does not exist."
                read -p "Would you like to make it? [Y/n] " response
                    case $response in
                        [Yy]* )
                            sudo mkdir "$INSTALLDIR"; break;;
                        [Nn]* ) exit;;
                        * )
                            echo ""
                            echo "Please answer Yes or No."
                            echo "";;
                    esac
                done
            fi
            INSTALLDIR="$INSTALLDIR"/root
            if [[ ! -e "$INSTALLDIR" ]]; then
                echo "Need sudo to make $INSTALLDIR"
                sudo mkdir "$INSTALLDIR"
            fi; break;;
            [Nn]* ) break;;
            * )
                echo ""
                echo "Please answer Yes or No."
                echo "";;
        esac
    done

    while true; do
    echo ""
    echo "#######################################################"
    echo "ROOT will be built in: $TLDIR"
    echo "ROOT will be installed in: $INSTALLDIR"
    echo "#######################################################"
    echo ""
    read -p "Is this all okay? [Y/n] " yn
        case $yn in
            [Yy]* )
                echo "Beginning installation!"
                echo ""; break;;
            [Nn]* ) exit;;
            * )
                echo ""
                echo "Please answer Yes or No."
                echo "";;
        esac
    done
}

function printResourceWarning () {
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
}

function setNumProcessors () {
    if [[ -f "$(which nproc)" ]]; then
        NPROC="$(nproc)"
    else
        NPROC="$(grep -c '^processor' /proc/cpuinfo)"
    fi

    while true; do
    echo "Your computer has ${NPROC} processors available for use during the build."
    read -p "Would you like to use a DIFFERENT number of processors? [Y/n] " yn
        case $yn in
            [Yy]* )
                read -r -e -p "Enter the number of processors you wish to use: " NPROC
                if [[ "${NPROC}" == 0 ]]; then
                    echo "At least 1 processor is required."
                    exit
                fi
            # Check if number of processors available
                if [[ "${NPROC}" -gt "$(grep -c '^processor' /proc/cpuinfo)" ]]; then
                    echo "The number of processors requested is more then is available."
                    exit
                fi; break;;
            [Nn]* )
                echo ""
                break;;
            * )
                echo ""
                echo "Please answer Yes or No."
                echo "";;
        esac
    done
}


function findMissingLIB () {
    MISSINGFILE="$1"
    if [ ! -f ${INSTALLDIR}/lib/${MISSINGFILE} ]; then
        LIBMISSINGPATH="$(find $HOME -iname ${MISSINGFILE} -print -quit 2>/dev/null)"
        if [ -n "$LIBMISSINGPATH" ]; then
            if [[ ! -d ${INSTALLDIR}/lib ]]; then
                sudo mkdir ${INSTALLDIR}/lib
            fi
            sudo cp ${LIBMISSINGPATH} ${INSTALLDIR}/lib/
        else
            echo "${MISSINGFILE} is not found under ${HOME}."
            echo "Make sure that you have ${MISSINGFILE} installed."
        fi
    fi
}

function setMissingLIB () {
    # As of 2016-12-02 the libpng16.so.16, libpcre.so.1, libiconv.so.2, and libjpeg.so.9
    # libraries are not gettting moved properly
    findMissingLIB "libpng16.so.16"
    findMissingLIB "libpcre.so.1"
    findMissingLIB "libiconv.so.2"
    findMissingLIB "libjpeg.so.9"
}

function stepCloneGit () {
    # Step 1
    echo ""
    echo "#######################################################"
    echo "Step $1: Clone the master branch of the Git repository"
    echo "from CERN"
    echo "Visit https://root.cern.ch/gitweb/?p=root.git for more"
    echo "#######################################################"
    echo "git clone http://root.cern.ch/git/root.git root_src"
    git clone http://root.cern.ch/git/root.git root_src
}

function stepPullGitMaster () {
    # Step 1
    echo ""
    echo "#######################################################"
    echo "Step $1: Pull from the master branch of the Git repository"
    echo "from CERN"
    echo "#######################################################"
    echo "cd root_src; git pull"
    cd ${TLDIR}/root_src
    if [[ "$(git pull)" == "Already up-to-date." ]]; then
        echo "Already up-to-date."
        echo "As master is up-to-date there is no need to currently rebuild."
        exit
    fi
}

function stepMakeBuildDir () {
    # Step 2
    echo ""
    echo "#######################################################"
    echo "Step $1: Create and navigate to the build directory for"
    echo "containing the build"
    echo "#######################################################"
    if [[ ! -d ${TLDIR}/root_build ]]; then
        echo "mkdir root_build; cd root_build"
        mkdir ${TLDIR}/root_build
    else
        echo "cd root_build"
    fi
    cd ${TLDIR}/root_build
}

function stepUnsetROOTSYS () {
    # Step 3
    echo ""
    echo "#######################################################"
    echo "Step $1: unset the ROOTSYS ENV variable"
    echo "#######################################################"
    echo "unset ROOTSYS"
    unset ROOTSYS
}

function stepConfigureCMake () {
    # Step 4
    echo ""
    echo "#######################################################"
    echo "Step $1: Execute the cmake command with the path to the"
    echo "top of your ROOT source tree"
    echo "#######################################################"
    echo "cmake -Dall=\"ON\" -Dsoversion=\"ON\" -Dqtgsi=\"OFF\" ../root_src"
    ##cmake -Dall="ON" -Dsoversion="ON" ../root_src >> cmake.out.txt 2>&1
    cmake -Dall="ON" -Dsoversion="ON" -Dqtgsi="OFF" ../root_src >> cmake.out.txt 2>&1
}

function stepBuild () {
    # Step 5
    echo ""
    echo "#######################################################"
    echo "Step $1: After CMake has finished running, proceed to"
    echo "start the build from the build directory"
    echo "N.B.: This will take a long time. Now is a good time to"
    echo "go for a coffee."
    echo "(To view progress do: tail -F root_build/cmake.out.txt)"
    echo "#######################################################"
    echo "cmake --build . -- -j${NPROC}"
    echo "" >> cmake.out.txt 2>&1
    date -u >> cmake.out.txt 2>&1
    #cmake --build . -- -j4 --target install >> cmake.out.txt 2>&1
    cmake --build . -- -j${NPROC} >> cmake.out.txt 2>&1
}

function stepMoveInstall () {
    # Step 6
    echo ""
    echo "#######################################################"
    echo "Step $1: Setting up the installation directory specified"
    echo "(To view progress do:"
    echo "tail -F root_build/cmake_install.out.txt)"
    echo "#######################################################"
    echo "sudo cmake -DCMAKE_INSTALL_PREFIX=${INSTALLDIR} -P cmake_install.cmake"
    echo "" >> cmake_install.out.txt 2>&1
    date -u >> cmake_install.out.txt 2>&1
    sudo cmake -DCMAKE_INSTALL_PREFIX=$INSTALLDIR -P cmake_install.cmake >> cmake_install.out.txt 2>&1
}

function stepPrintSourceInstructions () {
    # Last step
    echo ""
    echo "#######################################################"
    echo "Step $1: Setup the environment to run"
    echo "From where you installed root (${INSTALLDIR}/) do:"
    echo "source bin/thisroot.sh"
    echo "To test then run: which root"
    echo "To setup root at launch of shell add to your"
    echo "${USERSHELL}_profile:"
    echo "source <output of which root>/bin/thisroot.sh"
    echo "#######################################################"
}

function printRebuildInstructions () {
    # Last step
    echo ""
    echo "#######################################################"
    echo "To rebuild ROOT from an updated master branch simply do:"
    echo "${USERSHELL} installROOTsource.sh rebuild"
    echo "#######################################################"
}

function printUninstallInstructions () {
    # Last step
    echo ""
    echo "#######################################################"
    echo "To uninstall ROOT from this machine simply do:"
    echo "${USERSHELL} installROOTsource.sh uninstall"
    echo "#######################################################"
}

function install () {
    checkOS
    printResourceWarning
    setNumProcessors
    setInstallLocation

    # start install timer
    SECONDS=0

    checkPackages

    cd "$TLDIR"

    stepCloneGit 1
    stepMakeBuildDir 2
    stepUnsetROOTSYS 3

    # start build timer
    BUILDSTART=$SECONDS

    stepConfigureCMake 4

    setMissingLIB

    stepBuild 5
    stepMoveInstall 6

    #setLIBPNG

    # end install and build timers
    INSTALLTIME=$SECONDS
    BUILDTIME=$((${INSTALLTIME} - ${BUILDSTART}))

    echo ""
    echo "ROOT was installed in $(($INSTALLTIME / 60)) minutes and $(($INSTALLTIME % 60)) seconds"
    echo "and was built in $(($BUILDTIME / 60)) minutes and $(($BUILDTIME % 60)) seconds."
    echo ""

    stepPrintSourceInstructions 7
    printRebuildInstructions
    printUninstallInstructions
}

function rebuild () {
    checkOS
    printResourceWarning
    setNumProcessors
    setInstallLocation

    # start install timer
    SECONDS=0

    stepPullGitMaster 1

    # start build timer
    BUILDSTART=$SECONDS

    stepMakeBuildDir 2

    setMissingLIB

    stepBuild 3
    stepMoveInstall 4

    # end install and build timers
    INSTALLTIME=$SECONDS
    BUILDTIME=$((${INSTALLTIME} - ${BUILDSTART}))

    echo ""
    echo "ROOT was installed in $(($INSTALLTIME / 60)) minutes and $(($INSTALLTIME % 60)) seconds"
    echo "and was built in $(($BUILDTIME / 60)) minutes and $(($BUILDTIME % 60)) seconds."
    echo ""

    stepPrintSourceInstructions 5
    printRebuildInstructions
    printUninstallInstructions
}

function setUninstallLocation () {
    # Select the home directory as the top level directory
    BUILDDIR=~/

    while true; do
    echo "It is assumed that ROOT was built in your home directory: $BUILDDIR"
    read -p "Was ROOT built in a DIFFERENT directory? [Y/n] " yn
        case $yn in
            [Yy]* )
                # Check if path is empty string
                read -r -e -p "Enter the full file path of the directory:" BUILDDIR
                if [[ -z "$BUILDDIR" ]]; then
                    echo "That path you have entered is an empty string."
                    exit
                fi
                # Check if path does not exist
                if [[ ! -e "$BUILDDIR/root_src" ]]; then
                    echo "The directory root_src does does not exist in this path."
                    exit
                fi
                if [[ ! -e "$BUILDDIR/root_build" ]]; then
                    echo "The directory root_build does does not exist in this path."
                    exit
                fi; break;;
            [Nn]* ) break;;
            * )
                echo ""
                echo "Please answer Yes or No."
                echo "";;
        esac
    done

    echo ""
    # Default the install directory to be the build directory
    # TODO: For rebuild detect that 'which root' doesn't return null and start there
    INSTALLDIR="/usr/local/root/"

    while true; do
    echo "It is assumed that ROOT was installed in : $INSTALLDIR"
    read -p "Was ROOT installed in a DIFFERENT directory? [Y/n] " yn
        case $yn in
            [Yy]* )
            # Check if path is empty string
                read -r -e -p "Enter the full file path of the directory:" INSTALLDIR
                if [[ -z "$INSTALLDIR" ]]; then
                    echo "That path you have entered is an empty string."
                    exit
                fi
            # Check if path does not exist
                if [[ ! -e "$INSTALLDIR/bin/root" ]]; then
                    echo "The root install directory does not exist in this path."
                    exit
                fi; break;;
            [Nn]* ) break;;
            * )
                echo ""
                echo "Please answer Yes or No."
                echo "";;
        esac
    done

    while true; do
    echo ""
    echo "#######################################################"
    echo "ROOT will be uninstalled from $BUILDDIR and $INSTALLDIR"
    echo "#######################################################"
    echo ""
    read -p "Is this all okay? [Y/n] " yn
        case $yn in
            [Yy]* )
                echo "Beginning uninstall!"
                echo ""; break;;
            [Nn]* ) exit;;
            * )
                echo ""
                echo "Please answer Yes or No."
                echo "";;
        esac
    done
}

function findDir () {
    LOCATEDIR="$2"
    #DIRPATH="$(find $HOME -type d -iname ${LOCATEDIR} -print -quit 2>/dev/null)"
    DIRPATH="$(find $1 -type d -iname ${LOCATEDIR} -print -quit 2>/dev/null)"
    echo "$DIRPATH"
}

function uninstallROOT() {
    UNINSTALLBUILD="$(findDir $BUILDDIR root_build)"
    UNINSTALLSRC="$(findDir $BUILDDIR root_src)"
    UNINSTALLDIR="$(findDir $INSTALLDIR root)"

    echo ""
    echo "Removing the directories $UNINSTALLBUILD and $UNINSTALLSRC."
    sudo rm -rf "$UNINSTALLBUILD"
    sudo rm -rf "$UNINSTALLSRC"
    echo ""
    #TODO: Fix this rm problem
    echo "Removing the installation of ROOT from $INSTALLDIR."
    sudo rm -rf "$UNINSTALLDIR"

    echo ""
    echo "#######################################################"
    echo "ROOT has been successfully uninstalled."
    echo "To install ROOT again on this machine do:"
    echo "${USERSHELL} installROOTsource.sh"
    echo "#######################################################"
    echo ""
}

###
# Main program
###

function main () {
    getUserShell
    if [[ "$1" == "rebuild" ]]; then
        DIST=$(lsb_release -si)
        echo "ROOT will be rebuilt on ${DIST}."
        rebuild
    elif [[ "$1" == "uninstall" ]]; then
        setUninstallLocation
        uninstallROOT
    elif [[ "$1" == "install" ]]; then
        install
    else
        while true; do
        echo ""
        echo "#######################################################"
        echo "Would you like to:"
        echo "* [Install] ROOT"
        echo "* Update and [rebuild] ROOT"
        echo "* [Uninstall] ROOT"
        echo "#######################################################"
        echo ""
        read -p "Please enter 'install', 'rebuild', or 'uninstall': " response
            case $response in
                [Ii]* )
                    install; break;;
                [Rr]* )
                    DIST=$(lsb_release -si)
                    echo "ROOT will be rebuilt on ${DIST}."
                    rebuild; break;;
                [Uu]* )
                    setUninstallLocation
                    uninstallROOT; break;;
                * )
                    echo "";;
            esac
        done
    fi
}

###
# Run program
###

main $1
