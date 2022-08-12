#!/bin/bash
backtitle="EZ NODE UPDATER"

###################################
# sudo password for sudo commands #
###################################

if [[ "$(/usr/bin/whoami)" != "root" ]]; then
sudo -p "The script needs the admin/sudo password to continue, please enter: " date 2>/dev/null 1>&2
        if [ ! $? = 0 ]; then
            echo "You entered an invalid password. Script aborted."
            exit 1
        fi
fi

####################################
# Operating System (Linux) upgrade #
####################################
read -p "Update Operating System (Linux)? (yes or [no]): " INPUT

case $INPUT in
  y|yes)
        echo "Updating Operating System (Linux)... please wait"
        sleep 3
        sudo apt-get update        # command is used to download package information from all configured sources.
        sudo apt-get upgrade       # You run sudo apt-get upgrade to install available upgrades of all packages currently installed on the system from the sources configured via sources. list file. New packages will be installed if required to satisfy dependencies, but existing packages will never be removed
        ;;
*)
        echo "Skipped! The software upgrade will continue without updating the Operating System... please wait"
        sleep 3
        ;;
esac

###################
# Running prereqs #
###################

read -p "Update prereqs? (yes or [no]): " INPUT

case $INPUT in
    y|yes)
        {
        cd ~/tmp
        rm prereqs.sh

        read -p "Update prereqs from MASTER or ALPHA (test) branch? ([master] or alpha): " INPUT
        case $INPUT in
            a|alpha)
                echo "Downloading the latest prereqs file from ALPHA branch, please wait"
                sleep 3
                wget https://raw.githubusercontent.com/cardano-community/guild-operators/alpha/scripts/cnode-helper-scripts/prereqs.sh
                ;;

            *)
                echo "Downloading the latest prereqs file from MASTER branch, please wait"
                sleep 3
                wget https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/prereqs.sh
                ;;
        esac

        chmod +x prereqs.sh
        ./prereqs.sh
        }
        ;;

    *)
        {
        echo "Skipped! The software upgrade will continue without updating the prereq"
sleep 3
        }
        ;;
esac

#################################
# Node software upgrade section #
#################################


cd ~/git/cardano-node

# get list of recent releases
# TODO: handle no-connect errors
available=$(curl --stderr - https://github.com/input-output-hk/cardano-node/tags | \
        grep "<a href=\"/input-output-hk/cardano-node/releases/tag/" | \
        sed -e 's/.*\"\/input-output-hk\/cardano-node\/releases\/tag\/\(.*\)\".*/\1/' | \
        while read line; do n=$((++n)) && echo "$n: " "$line "; done)

# show list of releases in menu
selection=$(dialog --backtitle "$backtitle" --output-fd 1 --title "Select release to install" \
        --menu "Available recent releases:" 20 40 10 $available)
clear
# if nothing is selected, quit
if [ -z $selection ]; then
  clear
  echo "caradano-node software upgrade canceled"
  exit 1
fi

# grab the version number corresponding to the selected version
version=$(grep "${selection}" <<< "$available" | \
        sed -e 's/[0-9]: //' | \
        sed -e 's/ //')
echo Selected version: $version

echo "Checking for current version, please wait... "
sleep 3
# TODO: handle exception if cardano-node is not installed/found!
current_version=$(cardano-node --version | grep node | cut -c13-20)     # checking for the version running on server
echo "Current version running:" $current_version

if [ $current_version = $version ]; then
        {
        while true; do
        read -p "Version already installed, do you want to continue anyway? (yes or no) "  INPUT
                if [ "$INPUT" = "no" ]; then
                        echo "Upgrade skipped, software" $current_version "already installed!"
                        sleep 3
                        exit 1
                elif [ "$INPUT" = "yes" ]; then
                        echo "Upgrading cardano-node to" $current_version...
                        sleep 3
                else
                        echo  "yes or no"
                        continue
                fi
        break
        done
        }
fi

        echo "Stopping cardano-node..."
               sudo systemctl stop cnode
                sleep 10
        echo "Updating cabal, please wait..."
               cabal update
               cd ~/git
               sudo rm -R cardano-node
               git clone https://github.com/input-output-hk/cardano-node
               cd cardano-node

               git fetch --tags --all
               git checkout $version


               echo -e "package cardano-crypto-praos\n  flags: -external-libsodium-vrf" > cabal.project.local

         echo "Starting cardano-node software upgrade, it will take a while, meantime you can enjoy some coffee :)"
               $CNODE_HOME/scripts/cabal-build-all.sh

        echo "Software upgrade completed successfully , starting cardano-node... "
                sudo systemctl start cnode
                sleep 10
        cd $CNODE_HOME/scripts

{
while true; do

        read -p "cardano-node started, do you want to open gLiveView? (yes or no): " INPUT
                if [ "$INPUT" = "no" ]; then
                        echo "Good-bye!"
                        exit 1
                elif [ "$INPUT" = "yes" ]; then
                        echo "Opening gLiveView, please wait..."
                        sleep 3
                        ./gLiveView.sh
                else
                        echo  "yes or no"
                        continue
                fi
        break
        done
}
