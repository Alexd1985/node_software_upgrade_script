#!/bin/bash
backtitle="EZ NODE UPDATER"

###################################
# sudo password for sudo commands #
###################################

if [[ "$(/usr/bin/whoami)" != "root" ]]; then
  sudo -p "The script needs %U's password to continue, please enter: " date 2>/dev/null 1>&2
  if [ ! $? = 0 ]; then
    echo "You entered an invalid password. Script aborted."
    exit 1
  fi
fi

####################################
# Operating System (Linux) upgrade #
####################################

dialog --backtitle "$backtitle" --output-fd 1 --yes-label "Update" --extra-button \
    --extra-label "No" --cancel-label "Exit" --title "Update OS?" \
    --pause "Update linux install?\nDefault (yes)" 10 30 15

case $? in
  0)
    dialog --clear --nocancel --backtitle "$backtitle" --output-fd 1 --title "Update OS?" \
        --pause "Updating OS..." 10 30 5
    # command is used to download package information from all configured sources.
    sudo apt-get update
    # You run sudo apt-get upgrade to install available upgrades of all packages
    # currently installed on the system from the sources configured via sources.
    # list file. New packages will be installed if required to satisfy dependencies,
    # but existing packages will never be removed
    sudo apt-get upgrade
    ;;
  1)
    exit 1
    ;;
  *)
    dialog --clear --nocancel --backtitle "$backtitle" --output-fd 1 --title "Update OS?" \
        --pause "Skipped! The software upgrade will continue without updating the Operating System..." 10 50 5
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

# if nothing is selected, quit
if [ -z $selection ]; then
  clear
  echo "caradano-node software upgrade canceled"
  exit 1
fi

# automatically quit on first error from here on out
set -e

# grab the version number corresponding to the selected version
version=$(grep "${selection}" <<< "$available" | \
    sed -e 's/[0-9]: //' | sed -e 's/ //')

dialog --backtitle "$backtitle" --output-fd 1 \
    --pause "Selected version: $version" 10 30 10

# TODO: handle exception if cardano-node is not installed/found!
# check the current version running on server
current_version=$(cardano-node --version | grep node | cut -c13-20)

if [ $current_version = $version ]; then {
  dialog --backtitle "$backtitle" --output-fd 1 --title "Warning:" \
      --yesno "$version already installed, do you want to continue anyway?" 10 30
} fi

{
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
} | dialog --title "Updating cardano-node" --progressbox 30 100

dialog --backtitle "$backtitle" --output-fd 1 --title "start gLiveView?" \
    --pause "cardano-node started, do you want to open gLiveView?\nDefault to YES in 15 seconds" 10 40 15

case $? in
  0)
    cd $CNODE_HOME/scripts
    ./gLiveView.sh
    ;;
  *)
    dialog --clear --nocancel --backtitle "$backtitle" --output-fd 1 --title "Update Finished!" \
        --pause "Update Finished! exiting..." 10 50 5
    ;;
esac
