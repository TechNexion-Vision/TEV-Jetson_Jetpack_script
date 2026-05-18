#!/bin/bash

board_conf="$1"
DEV="$2"

update_extlinux() {
    local label=$1
    local dtb=$2
    local overlay=$3

    if grep -q "LABEL tn-${label}" extlinux.conf; then
        echo -ne "### tn-${label} configuration already exists, skip\n"
    else
        echo -ne "### add tn-${label} configuration\n"
        local conf=$(awk "/LABEL primary/,/APPEND /" extlinux.conf | \
            sed -e "s|LINUX /boot/Image|&\n      FDT ${dtb}\n      OVERLAYS ${overlay}|" | \
            sed "s/LABEL primary/LABEL tn-${label}/")
        sudo bash -c "echo -e '\n\n$conf' >> extlinux.conf"
    fi
    unset label dtb overlay conf
}

# ===========================
# ======== Main Entry =======
# ===========================
cd $CUR_DIR/Linux_for_Tegra/rootfs/boot/extlinux/
# 1. backup / restore extlinux.conf
if [[ ! -e "extlinux.conf.bak" ]];then
    sudo cp -rp extlinux.conf extlinux.conf.bak
else
    sudo cp -rp extlinux.conf.bak extlinux.conf
fi

# 2. edit boot menu
if [[ ${board_conf} == tn-tek6* ]]; then
    # tweak for close quiet for more dmesg
	sudo sed -i 's/APPEND \${cbootargs} quiet/APPEND \${cbootargs}/' extlinux.conf

elif [[ ${board_conf} == "tn-tek7000-orin-nx" ]]; then
    sudo sed -i 's/APPEND \${cbootargs} quiet/APPEND \${cbootargs}/' extlinux.conf
    DTB="tegra234-tek-orin+p3767-0000-nv.dtb"
    MODULES=("vls-gm2-8cam" "vls-gm2-4cam")
    for mod in "${MODULES[@]}"; do
        update_extlinux "$mod" "/boot/dtb/kernel_$DTB" "/boot/tegra234-p3767-camera-tek-orin-${mod}.dtbo"
    done

elif [[ ${board_conf} == "tn-tek7000-orin-nano" ]]; then
    sudo sed -i 's/APPEND \${cbootargs} quiet/APPEND \${cbootargs}/' extlinux.conf
    DTB="tegra234-tek-orin+p3767-0003-nv.dtb"
    MODULES=("vls-gm2-8cam" "vls-gm2-4cam")
    for mod in "${MODULES[@]}"; do
        update_extlinux "$mod" "/boot/dtb/kernel_$DTB" "/boot/tegra234-p3767-camera-tek-orin-${mod}.dtbo"
    done

elif [[ ${board_conf} == "jetson-orin-nano-devkit" ]]; then
    DTB="kernel_tegra234-p3768-0000+p3767-0005-nv.dtb"
    MODULES=("tevs-dual" "vls" "vls-gm2" "vls-gm2-fsync" "vls-gm2-tunnel" "vls-gm2-tunnel-fsync" "vls-gm2-fsync-external")
    for mod in "${MODULES[@]}"; do
        update_extlinux "$mod" "/boot/dtb/$DTB" "/boot/tegra234-p3767-camera-p3768-${mod}.dtbo"
    done

elif [[ ${board_conf} == "jetson-agx-orin-devkit" ]]; then
    DTB="kernel_tegra234-p3737-0000+p3701-0005-nv.dtb"
    MODULES=("vls-gm2" "vls-gm2-fsync" "vls-gm2-tunnel" "vls-gm2-tunnel-fsync" "vls-gm2-fsync-external")
    
    for mod in "${MODULES[@]}"; do
        update_extlinux "$mod" "/boot/dtb/$DTB" "/boot/tegra234-p3737-camera-${mod}-overlay.dtbo"
    done
fi

# 3. set default label
if [[ -n ${DEV} ]]; then
    echo -ne "### Setting DEFAULT for ${DEV}\n"
    sudo sed -i "s/DEFAULT .*/DEFAULT tn-${DEV}/" extlinux.conf
fi

cd $CUR_DIR