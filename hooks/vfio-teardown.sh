#!/bin/bash

#############################################################################
##     ______  _                _  _______         _                 _     ##
##    (_____ \(_)              | |(_______)       | |               | |    ##
##     _____) )_  _   _  _____ | | _    _   _   _ | |__   _____   __| |    ##
##    |  ____/| |( \ / )| ___ || || |  | | | | | ||  _ \ | ___ | / _  |    ##
##    | |     | | ) X ( | ____|| || |__| | | |_| || |_) )| ____|( (_| |    ##
##    |_|     |_|(_/ \_)|_____) \_)\______)|____/ |____/ |_____) \____|    ##
##                                                                         ##
#############################################################################
###################### Credits ###################### ### Update PCI ID'S ###
## Lily (PixelQubed) for editing the scripts       ## ##                   ##
## RisingPrisum for providing the original scripts ## ##   update-pciids   ##
## Void for testing and helping out in general     ## ##                   ##
## .Chris. for testing and helping out in general  ## ## Run this command  ##
## WORMS for helping out with testing              ## ## if you dont have  ##
##################################################### ## names in your     ##
## The VFIO community for using the scripts and    ## ## lspci feedback    ##
## testing them for us!                            ## ## in your terminal  ##
##################################################### #######################

################################# Variables #################################

## Adds current time to var for use in echo for a cleaner log and script ##
DATETIME=$(date +"%m/%d/%Y %R:%S :")

################################## Script ###################################

echo "$DATETIME Beginning of Teardown!"

## Unload VFIO-PCI driver ##
modprobe -r vfio_pci
modprobe -r vfio_iommu_type1
modprobe -r vfio

if grep -q "true" "/tmp/vfio-is-nvidia" ; then

    ## Load NVIDIA drivers ##
    echo "$DATETIME Loading NVIDIA GPU Drivers"
    
    modprobe drm
    modprobe drm_kms_helper
    modprobe i2c_nvidia_gpu
    modprobe nvidia
    modprobe nvidia_modeset
    modprobe nvidia_drm
    modprobe nvidia_uvm

    echo "$DATETIME NVIDIA GPU Drivers Loaded"
fi

if  grep -q "true" "/tmp/vfio-is-amd" ; then

    ## Load NVIDIA drivers ##
    echo "$DATETIME Loading AMD GPU Drivers"
    
    modprobe drm
    modprobe amdgpu
    modprobe radeon
    modprobe drm_kms_helper
    
    echo "$DATETIME AMD GPU Drivers Loaded"
fi

## Restart Display Manager ##
input="/tmp/vfio-store-display-manager"
while read -r DISPMGR; do
  if command -v systemctl; then

    ## Make sure the variable got collected ##
    echo "$DATETIME Var has been collected from file: $DISPMGR"

    systemctl start "$DISPMGR.service"

  else
    if command -v sv; then
      sv start "$DISPMGR"
    fi
  fi
done < "$input"

############################################################################################################
## Rebind VT consoles (adapted and modernised from https://www.kernel.org/doc/Documentation/fb/fbcon.txt) ##
############################################################################################################

input="/tmp/vfio-bound-consoles"
while read -r consoleNumber; do
  if test -x /sys/class/vtconsole/vtcon"${consoleNumber}"; then
      if [ "$(grep -c "frame buffer" "/sys/class/vtconsole/vtcon${consoleNumber}/name")" \
           = 1 ]; then
    echo "$DATETIME Rebinding console ${consoleNumber}"
	  echo 1 > /sys/class/vtconsole/vtcon"${consoleNumber}"/bind
      fi
  fi
done < "$input"


echo "$DATETIME End of Teardown!"
