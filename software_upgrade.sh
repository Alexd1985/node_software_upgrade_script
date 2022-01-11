#!/bin/bash


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
{
while true; do
                read -p "Update Operating System (Linux)? (yes or no): " INPUT
                if [ "$INPUT" = "no" ]; then
                        echo "Skipped! The software upgrade will continue without updating the Operating System... please wait"
                        sleep 2
                elif [ "$INPUT" = "yes" ]; then
                        echo "Updating Operating System (Linux)... please wait"
                        sleep 2
                        sudo apt-get update
                        sudo apt-get upgrade
                else
                        echo  "yes or no"
                        continue
                fi
break
done
}

#################################
# Node software upgrade section #
#################################


read -p "Enter version: " nversion
        echo "Checking for current version, please wait..."
        sleep 2
        sversion=$(cardano-node --version | grep node | cut -c13-20)
        echo "Current version running:" $sversion

if [ $sversion = $nversion ]; then
                        sleep 5
        {
        while true; do
                        read -p "Version already installed, do you want to continue anyway? (yes or no) "  INPUT
                        if [ "$INPUT" = "no" ]; then
                        echo "Upgrade skipped, software" $nversion "already installed!"
                        sleep 5
                        exit 1
                        elif [ "$INPUT" = "yes" ]; then
                        echo "Upgrading to" $nversion...
                        sleep 5
                        else
                        echo  "yes or no"
                        continue
                        fi
        break
        done
        }

fi


        echo "Upgrade started, it will take a while, meantime you can enjoy some coffee :)"
        sleep 5
        echo "Stopping the node..."
        sudo systemctl stop cnode
        sleep 10
                cabal update
                cd ~/git
                sudo rm -R cardano-node
                git clone https://github.com/input-output-hk/cardano-node
                cd cardano-node

                git fetch --tags --all
                git checkout $nversion


        echo -e "package cardano-crypto-praos\n  flags: -external-libsodium-vrf" > cabal.project.local
        $CNODE_HOME/scripts/cabal-build-all.sh

        echo "The software upgrade is succesful, starting the node"
        sudo systemctl start cnode
        sleep 10
        echo "The node has been started... opening gLiveView!"
        sleep 3
        cd $CNODE_HOME/scripts
        ./gLiveView.sh
