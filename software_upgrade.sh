#!/bin/bash
# shellcheck disable=SC2086,SC1090,SC2059
# shellcheck source=/dev/null
backtitle="EZ NODE UPDATER"

##########################################
# User Variables - Change as desired     #
# command line flags override set values #
##########################################
CURL_TIMEOUT=60        # Maximum time in seconds that you allow the file download operation to take before aborting (Default: 60s)
UPDATE_CHECK='N'       # Check if there is an updated version of software upgrade script to download



#######################
#  CHECK FOR UPDATES  #
#######################

shift $((OPTIND -1))

[[ -z ${CURL_TIMEOUT} ]] && CURL_TIMEOUT=60
[[ -z ${UPDATE_CHECK} ]] && UPDATE_CHECK='Y'

get_input() {
  printf "%s (default: %s): " "$1" "$2" >&2; read -r answer
  if [ -z "$answer" ]; then echo "$2"; else echo "$answer"; fi
}

get_answer() {
  printf "%s (yes/no): " "$*" >&2; read -r answer
  while : 
  do
    case $answer in
    [Yy]*)
      return 0;;
    [Nn]*)
      return 1;;
    *) printf "%s" "Please enter 'yes' or 'no' to continue: " >&2; read -r answer
    esac
  done
}

URL_RAW="https://raw.githubusercontent.com/Alexd1985/node_software_upgrade_script/main/software_upgrade.sh"

# Check if software_upgrade.sh update is available
PARENT="/opt/cardano/cnode/scripts"
if [[ ${UPDATE_CHECK} = 'Y' ]] && curl -s -f -m ${CURL_TIMEOUT} -o "${PARENT}"/software_upgrade.sh.tmp ${URL_RAW} 2>/dev/null; then
  TEMPL_CMD=$(awk '/^backtitle/,0' "${PARENT}"/software_upgrade.sh)
  TEMPL2_CMD=$(awk '/^backtitle/,0' "${PARENT}"/software_upgrade.sh.tmp)
  if [[ "$(echo ${TEMPL_CMD} | sha256sum)" != "$(echo ${TEMPL2_CMD} | sha256sum)" ]]; then
    if get_answer "A new version of software_upgrade script is available, do you want to download the latest version?"; then
      cp "${PARENT}"/software_upgrade.sh "${PARENT}/software_upgrade.sh_bkp$(date +%s)"
      STATIC_CMD=$(awk '/#!/{x=1}/^backtitle/{exit} x' "${PARENT}"/software_upgrade.sh)
      printf '%s\n%s\n' "$STATIC_CMD" "$TEMPL2_CMD" > "${PARENT}"/software_upgrade.sh.tmp
      {
        mv -f "${PARENT}"/software_upgrade.sh.tmp "${PARENT}"/software_upgrade.sh && \
        chmod 755 "${PARENT}"/software_upgrade.sh && \
        echo -e "\nUpdate applied successfully, please run software upgrade again!\n" && \
        exit 0; 
      } || {
        echo -e "Update failed!\n\nPlease manually download latest version of software upgrade script from GitHub" && \
        exit 1;
      }
    fi
  fi
fi
 rm -f "${PARENT}"/software_upgrade.sh.tmp


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
        echo "Updating Operating System (Linux), please wait"
        sleep 3
        sudo apt-get update        # command is used to download package information from all configured sources.
        sudo apt-get upgrade       # You run sudo apt-get upgrade to install available upgrades of all packages currently installed on the system from the sources configured via sources. list file. New packages will be installed if required to satisfy dependencies, but existing packages will never be removed
        ;;
*)
        echo "Skipped! The software upgrade will continue without updating the Operating System, please wait"
        sleep 3
        ;;
esac

###################
# Running prereqs #
###################

read -p "Update prereqs and download the latest scripts/files? (yes or [no]): " INPUT

case $INPUT in
    y|yes)
       
        cd ~/tmp
        rm prereqs.sh                                                                                                            # this command will delete the last/old prereqs file
        wget https://raw.githubusercontent.com/cardano-community/guild-operators/master/scripts/cnode-helper-scripts/prereqs.sh  # this command will download the latest prereqs file
        chmod +x prereqs.sh                                                                                                      # this command will make the file executable
                echo "Downloading the latest scripts/files, please wait"
                ./prereqs.sh
                
       sleep1 
        
        ;;

    *)
        
        echo "Skipped! The software upgrade will continue without updating the prereqs"
sleep 1
        
        ;;
esac

#################################
# Node software upgrade section #
#################################


cd ~/git/cardano-node

# get list of recent releases
# TODO: handle no-connect errors
available=$(curl --stderr - https://github.com/input-output-hk/cardano-node/tags | grep tag | grep -v dat | grep -v refs | grep releases | cut -d \/ -f6 | cut -d\" -f1 | grep -v ^$ | \
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
