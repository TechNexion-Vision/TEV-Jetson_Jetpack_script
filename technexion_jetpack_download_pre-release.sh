#!/bin/bash

TIME=$(date +'%Y%m%d')
CUR_DIR="$(pwd)/"
NV_TAG="tegra-l4t-r32.7.1"
TAG="pre-release"
TEK3_TAG="${TAG}_TEK3-NVJETSON-a1"
TEK8_TAG="${TAG}_TEK8-NX210V-a1"
BRANCH="tn_l4t-r32.7.1_kernel-4.9"
TEK3_BRANCH="${BRANCH}_TEK3-NVJETSON-a1"
TEK8_BRANCH="${BRANCH}_TEK8-NX210V-a1"
# Wether using ssh to download github source code
USING_SSH=0

# Wether using tag to download stable release
USING_TAG=1

get_nvidia_jetpack() {
	echo -ne "\n### Get nvidia jetpack source code\n"
	if [[ $m == "Nano" ]];then
		echo -ne "Download Nano Jetpack\n"
		JETPACK="https://developer.nvidia.com/embedded/l4t/r32_release_v7.1/t210/jetson-210_linux_r32.7.1_aarch64.tbz2"
		ROOTFS="https://developer.nvidia.com/embedded/l4t/r32_release_v7.1/t210/tegra_linux_sample-root-filesystem_r32.7.1_aarch64.tbz2"
		PUBLIC="https://developer.nvidia.com/embedded/l4t/r32_release_v7.1/sources/t210/public_sources.tbz2"
	elif [[ $m == "Xavier-NX" ]];then
		echo -ne "Download Xavier NX Jetpack\n"
		JETPACK="https://developer.nvidia.com/embedded/l4t/r32_release_v7.1/t186/jetson_linux_r32.7.1_aarch64.tbz2"
		ROOTFS="https://developer.nvidia.com/embedded/l4t/r32_release_v7.1/t186/tegra_linux_sample-root-filesystem_r32.7.1_aarch64.tbz2"
		PUBLIC="https://developer.nvidia.com/embedded/l4t/r32_release_v7.1/sources/t186/public_sources.tbz2"
	fi
    
	wget $JETPACK -q --tries=10 -O jetpack.tbz2
	wget $ROOTFS -q --tries=10 -O rootfs.tbz2
	wget $PUBLIC -q --tries=10 -O public.tbz2

	tar -jxf jetpack.tbz2
	tar -jxf public.tbz2
	sudo tar -jxf rootfs.tbz2 -C Linux_for_Tegra/rootfs

	rm -rf jetpack.tbz2 rootfs.tbz2 public.tbz2
	cd ${CUR_DIR}
	echo -ne "done\n"
}

run_nvidia_script_and_sync_code() {
	echo -ne "\n### Run nvidia script to get require sources\n"
	cd Linux_for_Tegra/
	sudo ./apply_binaries.sh

	echo -ne "\n### Clone nvidia source code\n"
	# tweak for nvidia script error
	sed -i 's/k\:hardware\/nvidia\/platform\/t19x\/galen-industrial-dts/k\:hardware\/nvidia\/platform\/t19x\/galen-industrial/' source_sync.sh
	./source_sync.sh -t ${NV_TAG}
	cd ${CUR_DIR}
	echo -ne "done\n"
}

sync_tn_source_code() {
	echo -ne "\n### Clone source code from Technexion github\n"

	echo -ne "# kernel\n"
	cd Linux_for_Tegra/sources/kernel/kernel-4.9/
	if [[ $USING_SSH -eq 0 ]];then
		git remote add tn-github https://github.com/TechNexion-Vision/TEV-Jetson_kernel.git
	else
		git remote add tn-github git@github.com:TechNexion-Vision/TEV-Jetson_kernel.git
	fi
	git fetch tn-github ${BRANCH}
	git checkout -b ${BRANCH} tn-github/${BRANCH}
	if [[ $USING_TAG -eq 1 ]];then
		git reset --hard $TAG
	fi
	cd ${CUR_DIR}

	echo -ne "# dts\n"
	if [[ $m == "Nano" ]];then
		cd Linux_for_Tegra/sources/hardware/nvidia/platform/t210/porg/
		if [[ $USING_SSH -eq 0 ]];then
			git remote add tn-github https://github.com/TechNexion-Vision/TEV-JetsonNano_device-tree.git
		else
			git remote add tn-github git@github.com:TechNexion-Vision/TEV-JetsonNano_device-tree.git
		fi
	elif [[ $m == "Xavier-NX" ]];then
		cd Linux_for_Tegra/sources/hardware/nvidia/platform/t19x/jakku/kernel-dts/
		if [[ $USING_SSH -eq 0 ]];then
			git remote add tn-github https://github.com/TechNexion-Vision/TEV-JetsonXavier-NX_device-tree.git
		else
			git remote add tn-github git@github.com:TechNexion-Vision/TEV-JetsonXavier-NX_device-tree.git
		fi	
	fi
	git fetch tn-github ${BRANCH}
	git checkout -b ${BRANCH} tn-github/${BRANCH}
	if [[ $USING_TAG -eq 1 ]];then
		git reset --hard $TAG
	fi
	cd ${CUR_DIR}

	echo -ne "# technexion camera drivers\n"
	cd Linux_for_Tegra/sources/kernel/
	if [[ $USING_SSH -eq 0 ]];then
		git clone https://github.com/TechNexion-Vision/TEV-Jetson_Camera_driver.git technexion
	else
		git clone git@github.com:TechNexion-Vision/TEV-Jetson_Camera_driver.git technexion
	fi
	cd technexion
	git checkout $BRANCH
	if [[ $USING_TAG -eq 1 ]];then
		git reset --hard $TAG
	fi
	cd ${CUR_DIR}

	echo -ne "# technexion pinmux file(xlsm)\n"
	cd Linux_for_Tegra/sources/
	if [ $m == "Xavier-NX" ] && [ $b == "TEK3-NVJETSON" ];then
		if [[ $USING_SSH -eq 0 ]];then
			git clone https://github.com/TechNexion-Vision/TEV-JetsonXavier-NX_pinmux.git TEK3-NVJETSON_Xavier-NX_pinmux
		else
			git clone git@github.com:TechNexion-Vision/TEV-JetsonXavier-NX_pinmux.git TEK3-NVJETSON_Xavier-NX_pinmux
		fi
		cd TEK3-NVJETSON_Xavier-NX_pinmux
		git checkout ${TEK3_BRANCH}
		if [[ $USING_TAG -eq 1 ]];then
			git reset --hard ${TEK3_TAG}
		fi
	elif [ $m == "Nano" ] && [ $b == "TEK3-NVJETSON" ];then
		if [[ $USING_SSH -eq 0 ]];then
			git clone https://github.com/TechNexion-Vision/TEV-JetsonNano_pinmux.git TEK3-NVJETSON_Nano_pinmux
		else
			git clone git@github.com:TechNexion-Vision/TEV-JetsonNano_pinmux.git TEK3-NVJETSON_Nano_pinmux
		fi
		cd TEK3-NVJETSON_Nano_pinmux
		git checkout ${TEK3_BRANCH}
		if [[ $USING_TAG -eq 1 ]];then
			git reset --hard ${TEK3_TAG}
		fi
	elif [ $m == "Xavier-NX" ] && [ $b == "TEK8-NX210V" ];then
		if [[ $USING_SSH -eq 0 ]];then
			git clone https://github.com/TechNexion-Vision/TEV-JetsonXavier-NX_pinmux.git TEK8-NX210V_Xavier-NX_pinmux
		else
			git clone git@github.com:TechNexion-Vision/TEV-JetsonXavier-NX_pinmux.git TEK8-NX210V_Xavier-NX_pinmux
		fi
		cd TEK8-NX210V_Xavier-NX_pinmux
		git checkout ${TEK8_BRANCH}
		if [[ $USING_TAG -eq 1 ]];then
			git reset --hard ${TEK8_TAG}
		fi
	fi
	cd ${CUR_DIR}

	if [ $m == "Nano" ] && [ $b == "TEK3-NVJETSON" ];then
		echo -ne "# u-boot\n"
		cd Linux_for_Tegra/sources/u-boot/
		if [[ $USING_SSH -eq 0 ]];then
			git remote add tn-github https://github.com/TechNexion-Vision/TEV-JetsonNano_u-boot.git
		else
			git remote add tn-github git@github.com:TechNexion-Vision/TEV-JetsonNano_u-boot.git
		fi
		git fetch tn-github ${TEK3_BRANCH}
		git checkout -b ${TEK3_BRANCH} tn-github/${TEK3_BRANCH}
		if [[ $USING_TAG -eq 1 ]];then
			git reset --hard ${TEK3_TAG}
		fi
		cd ${CUR_DIR}
	fi

	if [[ $m == "Xavier-NX" ]];then
		echo -ne "# cboot\n"
		cd Linux_for_Tegra/sources/
		if [[ $USING_SSH -eq 0 ]];then
			git clone https://github.com/TechNexion-Vision/TEV_JetsonXavierNX_Cboot.git cboot
		else
			git clone git@github.com:TechNexion-Vision/TEV_JetsonXavierNX_Cboot.git cboot
		fi
		cd cboot
		git pull origin
		git checkout ${BRANCH}
		if [[ $USING_TAG -eq 1 ]];then
			git reset --hard ${TAG}
		fi
		cd ${CUR_DIR}
	fi

	echo -ne "done\n"
}

create_gcc_tool_chain () {
	echo -ne "\n### Download gcc tool chain\n"
	cd Linux_for_Tegra/sources/kernel/
	mkdir -p gcc_tool_chain
	cd gcc_tool_chain/
	GCC_TOOL_CHAIN="$(pwd)/"
	wget -q --no-check-certificate https://releases.linaro.org/components/toolchain/binaries/7.4-2019.02/aarch64-linux-gnu/gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu.tar.xz --tries=10
	tar Jxf gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu.tar.xz
	echo -ne "done\n"
	cd ${CUR_DIR}
}

create_kernel_compile_script () {
	echo -ne "\n### Download kernel compile script\n"
	cd Linux_for_Tegra/sources/kernel/kernel-4.9/
	echo -e "#!/bin/bash" > environment_arm64_gcc7.sh
	echo -e "export GCC_DIR=${GCC_TOOL_CHAIN}" >> environment_arm64_gcc7.sh
	echo -e "export ARCH=arm64" >> environment_arm64_gcc7.sh
	echo -e "export CROSS_COMPILE=\${GCC_DIR}/gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-" >> environment_arm64_gcc7.sh
	echo -e "export CROSS_COMPILE_AARCH64_PATH=\${GCC_DIR}/gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu/" >> environment_arm64_gcc7.sh
	chmod 777 environment_arm64_gcc7.sh

	echo -e "#!/bin/bash\n" > compile_kernel.sh
	echo -e "source environment_arm64_gcc7.sh" >> compile_kernel.sh
	echo -e "make tegra_tn_defconfig\n" >> compile_kernel.sh
	echo -e "#Compile kernel" >> compile_kernel.sh
	echo -e "make LOCALVERSION=-tegra -j\$(nproc) Image" >> compile_kernel.sh
	echo -e "#Compile DTBs" >> compile_kernel.sh
	echo -e "make LOCALVERSION=-tegra -j\$(nproc) dtbs" >> compile_kernel.sh
	echo -e "#Compile modules" >> compile_kernel.sh
	echo -e "make LOCALVERSION=-tegra -j\$(nproc) modules\n" >> compile_kernel.sh
	echo -e "#Install kernel modules" >> compile_kernel.sh
	echo -e "mkdir -p ../modules" >> compile_kernel.sh
	echo -e "make LOCALVERSION=-tegra INSTALL_MOD_PATH=../modules modules_install" >> compile_kernel.sh
	chmod 777 compile_kernel.sh

	cd ${CUR_DIR}
	echo -ne "done\n"
}

create_u-boot_compile_script () {
	echo -ne "\n### Download u-boot compile script\n"
	cd Linux_for_Tegra/sources/u-boot
	echo -e "#!/bin/bash" > environment_arm64_gcc7.sh
	echo -e "export GCC_DIR=${GCC_TOOL_CHAIN}" >> environment_arm64_gcc7.sh
	echo -e "export ARCH=arm64" >> environment_arm64_gcc7.sh
	echo -e "export CROSS_COMPILE=\${GCC_DIR}/gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-" >> environment_arm64_gcc7.sh
	echo -e "export CROSS_COMPILE_AARCH64_PATH=\${GCC_DIR}/gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu/" >> environment_arm64_gcc7.sh
	chmod 777 environment_arm64_gcc7.sh

	echo -e "#!/bin/bash\n" > compile_u-boot.sh
	echo -e "source environment_arm64_gcc7.sh" >> compile_u-boot.sh
	echo -e "make p3450-0000_defconfig\n" >> compile_u-boot.sh
	echo -e "make -j\$(nproc)" >> compile_u-boot.sh
	chmod 777 compile_u-boot.sh
	cd ${CUR_DIR}
	echo -ne "done\n"
}

create_cboot_compile_script () {
	echo -ne "\n### Download cboot compile script\n"
	cd Linux_for_Tegra/sources/cboot
	echo -e "#!/bin/bash" > environment_arm64_gcc7.sh
	echo -e "export GCC_DIR=${GCC_TOOL_CHAIN}" >> environment_arm64_gcc7.sh
	echo -e "export ARCH=arm64" >> environment_arm64_gcc7.sh
	echo -e "export CROSS_COMPILE=\${GCC_DIR}/gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-" >> environment_arm64_gcc7.sh
	echo -e "export CROSS_COMPILE_AARCH64_PATH=\${GCC_DIR}/gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu/" >> environment_arm64_gcc7.sh
	chmod 777 environment_arm64_gcc7.sh

	echo -e "#!/bin/bash\n" > compile_cboot.sh
	echo -e "source environment_arm64_gcc7.sh" >> compile_cboot.sh
	echo -e "export TEGRA_TOP=\$PWD" >> compile_cboot.sh
	echo -e "make -C ./bootloader/partner/t18x/cboot PROJECT=t194 TOOLCHAIN_PREFIX="\${CROSS_COMPILE}"  DEBUG=2 BUILDROOT="\${PWD}"/out NV_TARGET_BOARD=t194ref NV_BUILD_SYSTEM_TYPE=l4t NOECHO=@\n" >> compile_cboot.sh
	chmod 777 compile_cboot.sh
	cd ${CUR_DIR}
	echo -ne "done\n"
}

compile_kernel_for_24_cam (){
	echo -ne "\n### compile tweak kernel for 24-cam\n"
	cd Linux_for_Tegra/sources/kernel/technexion/
	git checkout tn_l4t-r32.7.1_kernel-4.9_serdes_24cam
	cd ${CUR_DIR}

	cd Linux_for_Tegra/sources/kernel/kernel-4.9/
	./compile_kernel.sh
	# backup tweak kernel
	mv arch/arm64/boot/Image arch/arm64/boot/Image_24-cam
	cd ${CUR_DIR}

	echo -ne "done\n"
}

compile_kernel (){
	echo -ne "\n### compile kernel\n"
	cd Linux_for_Tegra/sources/kernel/kernel-4.9/
	./compile_kernel.sh

	cd ${CUR_DIR}
	echo -ne "done\n"
}

compile_u-boot (){
	echo -ne "\n### compile u-boot\n"
	cd Linux_for_Tegra/sources/u-boot
	./compile_u-boot.sh

	cd ${CUR_DIR}
	echo -ne "done\n"
}

compile_cboot (){
	echo -ne "\n### compile cboot\n"
	cd Linux_for_Tegra/sources/cboot
	./compile_cboot.sh

	cd ${CUR_DIR}
	echo -ne "done\n"
}

create_demo_image (){
	echo -ne "\n### create demo_image\n"
	# copy kernel image
	if [ $m == "Xavier-NX" ] && [ $b == "TEK8-NX210V" ];then
		sudo cp -rp Linux_for_Tegra/sources/kernel/kernel-4.9/arch/arm64/boot/Image_24-cam Linux_for_Tegra/kernel/
		sudo cp -rp Linux_for_Tegra/sources/kernel/kernel-4.9/arch/arm64/boot/Image_24-cam Linux_for_Tegra/rootfs/boot/
	else
		sudo cp -rp Linux_for_Tegra/sources/kernel/kernel-4.9/arch/arm64/boot/Image Linux_for_Tegra/kernel/
		sudo cp -rp Linux_for_Tegra/sources/kernel/kernel-4.9/arch/arm64/boot/Image Linux_for_Tegra/rootfs/boot/
	fi
	sudo rm -rf Linux_for_Tegra/kernel/Image.gz
	# copy kernel modules
	sudo cp -rp Linux_for_Tegra/sources/kernel/modules/lib/ Linux_for_Tegra/rootfs/
	# copy device-tree
	if [ $m == "Nano" ] && [ $b == "EVK" ];then
		sudo cp -rp Linux_for_Tegra/sources/kernel/kernel-4.9/arch/arm64/boot/dts/tegra210-p3448-0000-p3449-0000-b00-tn.dtb Linux_for_Tegra/rootfs/boot/
		sudo cp -rp Linux_for_Tegra/sources/kernel/kernel-4.9/arch/arm64/boot/dts/tegra210-p3448-all-p3449-0000-tevi-ap1302-dual.dtbo Linux_for_Tegra/rootfs/boot/
	elif [ $m == "Nano" ] && [ $b == "TEK3-NVJETSON" ];then
		sudo cp -rp Linux_for_Tegra/sources/kernel/kernel-4.9/arch/arm64/boot/dts/tegra210-tek3-nvjetson-a1.dtb Linux_for_Tegra/rootfs/boot/
		sudo cp -rp Linux_for_Tegra/sources/kernel/kernel-4.9/arch/arm64/boot/dts/tegra210-tek3-nvjetson-a1-no-vizionlink.dtb Linux_for_Tegra/rootfs/boot/ # For DVT
	elif [[ $m == "Xavier-NX" ]];then
		if [[ $b == "TEK3-NVJETSON" ]];then
			sudo cp -rp Linux_for_Tegra/sources/kernel/kernel-4.9/arch/arm64/boot/dts/tegra194-p3668-tek3-nvjetson-a1.dtb Linux_for_Tegra/rootfs/boot/
			sudo cp -rp Linux_for_Tegra/sources/kernel/kernel-4.9/arch/arm64/boot/dts/tegra194-p3668-tek3-nvjetson-a1-no-vizionlink.dtb Linux_for_Tegra/rootfs/boot/ # For DVT
		elif [[ $b == "TEK8-NX210V" ]];then
			sudo cp -rp Linux_for_Tegra/sources/kernel/kernel-4.9/arch/arm64/boot/dts/tegra194-p3668-tek8-nx210v-a1-24-cam.dtb Linux_for_Tegra/rootfs/boot/
		fi
		# tweak: dp pinmux will use origin dtb, we must update it.
		sudo cp -rp Linux_for_Tegra/sources/kernel/kernel-4.9/arch/arm64/boot/dts/tegra194-p3668-all-p3509-0000.dtb Linux_for_Tegra/kernel/dtb/
	fi
	# copy u-boot.bin (tweak for TEK3-NVJETSON with Nano)
	if [ $m == "Nano" ] && [ $b == "TEK3-NVJETSON" ];then
		sudo cp -rp Linux_for_Tegra/sources/u-boot/u-boot.bin Linux_for_Tegra/bootloader/t210ref/p3450-0000/
	fi
	# copy lk.bin of cboot
	if [ $m == "Xavier-NX" ];then
		sudo cp -rp Linux_for_Tegra/sources/cboot/out/build-t194/lk.bin Linux_for_Tegra/bootloader/cboot_t194.bin
	fi
	# copy pinmux file (Xavier-NX only)
	if [ $m == "Xavier-NX" ] && [ $b == "TEK3-NVJETSON" ];then
		sudo cp -rp Linux_for_Tegra/sources/TEK3-NVJETSON_Xavier-NX_pinmux/tegra19x-mb1-pinmux-p3668-a01.cfg Linux_for_Tegra/bootloader/t186ref/BCT/
	elif [ $m == "Xavier-NX" ] && [ $b == "TEK8-NX210V" ];then
		sudo cp -rp Linux_for_Tegra/sources/TEK8-NX210V_Xavier-NX_pinmux/tegra19x-mb1-pinmux-p3668-a01.cfg Linux_for_Tegra/bootloader/t186ref/BCT/
	fi
	# copy flash FPGA firmware service
	if [ $m == "Xavier-NX" ] && [ $b == "TEK8-NX210V" ];then
		if [[ $USING_SSH -eq 0 ]];then
			git clone https://github.com/TechNexion-Vision/TEV-JetsonXavier-NX_TEK8_FPGA_Flash.git FPGA
		else
			git clone git@github.com:TechNexion-Vision/TEV-JetsonXavier-NX_TEK8_FPGA_Flash.git FPGA
		fi
		cd FPGA
		git checkout ${TEK8_BRANCH}
		if [[ $USING_TAG -eq 1 ]];then
			git reset --hard ${TEK8_TAG}
		fi
		cd ${CUR_DIR}
		sudo cp -rp FPGA/etc/ Linux_for_Tegra/rootfs/
		sudo cp -rp FPGA/usr/ Linux_for_Tegra/rootfs/
		rm -rf FPGA/
	fi

	# copy QCA9377 firmware from github
	git clone https://github.com/kvalo/ath10k-firmware.git QCA9377_WIFI
	git clone https://oauth2:SbtQ_mC4fvJRA88_9jB7@gitlab.com/technexion-imx/qca_firmware.git QCA9377_BT
	sudo cp -rv QCA9377_WIFI/QCA9377/hw1.0/board-2.bin Linux_for_Tegra/rootfs/lib/firmware/ath10k/QCA9377/hw1.0
	sudo cp -rv QCA9377_WIFI/QCA9377/hw1.0/board.bin Linux_for_Tegra/rootfs/lib/firmware/ath10k/QCA9377/hw1.0
	sudo cp -rv QCA9377_WIFI/LICENSE.qca_firmware Linux_for_Tegra/rootfs/lib/firmware/ath10k/QCA9377/hw1.0
	sudo cp -rv QCA9377_WIFI/QCA9377/hw1.0/CNSS.TF.1.0/firmware-5.bin_CNSS.TF.1.0-00267-QCATFSWPZ-1 Linux_for_Tegra/rootfs/lib/firmware/ath10k/QCA9377/hw1.0/firmware-5.bin
	sudo cp -rv QCA9377_BT/qca/notice.txt Linux_for_Tegra/rootfs/lib/firmware/qca
	sudo cp -rv QCA9377_BT/qca/nvm_usb_00000302.bin Linux_for_Tegra/rootfs/lib/firmware/qca
	sudo cp -rv QCA9377_BT/qca/rampatch_usb_00000302.bin Linux_for_Tegra/rootfs/lib/firmware/qc
	rm -rf QCA9377_WIFI
	rm -rf QCA9377_BT

	# copy change boot config
	cd Linux_for_Tegra/rootfs/boot/extlinux/
	# close quiet for more dmesg
	sudo sed -i 's/APPEND \${cbootargs} quiet/APPEND \${cbootargs}/' extlinux.conf
	if [ $m == "Xavier-NX" ] && [ $b == "TEK3-NVJETSON" ];then
		sudo sed -i '10i \ \ \ \ \ \ FDT /boot/tegra194-p3668-tek3-nvjetson-a1.dtb' extlinux.conf
	elif [ $m == "Nano" ] && [ $b == "EVK" ];then
		sudo sed -i '10i \ \ \ \ \ \ FDT /boot/tegra210-p3448-0000-p3449-0000-b00-tn.dtb' extlinux.conf
		sudo sed -i '11i \ \ \ \ \ \ FDTOVERLAYS /boot/tegra210-p3448-all-p3449-0000-tevi-ap1302-dual.dtbo' extlinux.conf
	elif [ $m == "Nano" ] && [ $b == "TEK3-NVJETSON" ];then
		sudo sed -i '10i \ \ \ \ \ \ FDT /boot/tegra210-tek3-nvjetson-a1.dtb' extlinux.conf
	elif [ $m == "Xavier-NX" ] && [ $b == "TEK8-NX210V" ];then
		sudo sed -i 's|LINUX /boot/Image|LINUX /boot/Image_24-cam|' extlinux.conf
		sudo sed -i '10i \ \ \ \ \ \ FDT /boot/tegra194-p3668-tek8-nx210v-a1-24-cam.dtb' extlinux.conf
	fi
	cd ${CUR_DIR}

	# create new demo_image
	cd Linux_for_Tegra/
	if [ $m == "Nano" ] && [ $b == "TEK3-NVJETSON" ];then
		sudo ./flash.sh --no-flash jetson-nano-devkit-emmc mmcblk0p1
	elif [ $m == "Nano" ] && [ $b == "EVK" ];then
		sudo ./flash.sh --no-flash jetson-nano-devkit mmcblk0p1
	elif [[ $m == "Xavier-NX" ]];then
		sudo ./flash.sh --no-flash jetson-xavier-nx-devkit-emmc mmcblk0p1
	fi
	cd ${CUR_DIR}
	echo -ne "done\n"
}

usage() {
	echo -e "$0 \ndownload the Technexion Jetpack [-m <Xavier-NX|Nano>] [-b <TEK3-NVJETSON|TEK8-NX210V|EVK>]" 1>&2
	echo "-m: module <Xavier-NX|Nano>" 1>&2
	echo "-b: baseboard <TEK3-NVJETSON|TEK8-NX210V|EVK>" 1>&2
	echo "" 1>&2
	echo "Support combination:" 1>&2
	echo "Xavier-NX: TEK3-NVJETSON|TEK8-NX210V" 1>&2
	echo "     Nano: TEK3-NVJETSON|EVK" 1>&2
	exit 1
}

do_job () {
	CUR_DIR="$(pwd)/"
	get_nvidia_jetpack
	run_nvidia_script_and_sync_code

	sync_tn_source_code
	create_gcc_tool_chain

	create_kernel_compile_script
	if [[ $b == "TEK8-NX210V" ]];then
		compile_kernel_for_24_cam
	else
		compile_kernel
	fi

	if [[ $m == "Nano" ]];then
		create_u-boot_compile_script
		compile_u-boot
	fi

	if [ $m == "Xavier-NX" ];then
		create_cboot_compile_script
		compile_cboot
	fi

	create_demo_image
	echo -ne "\n### Finish\n"
}


### Script start from here
set -e

Error_appears () {
    if [ $? -ne 0 ]
    then
        echo "##### script was running failed due to previous error!! #####"
    fi
}
trap Error_appears EXIT

if [ "$(id -u)" = "0" ]; then
	echo "This script can not be run as root"
	exit 1
fi

while getopts ":m:b:" o; do
    case "${o}" in
        m)
            m=${OPTARG}
	    if [ ${m} != "Xavier-NX" ] && [ ${m} != "Nano" ];then
		    echo -e "### invalid module\n\n"; usage
	    fi
            ;;
        b)
            b=${OPTARG}
	    if [ ${b} != 'TEK3-NVJETSON' ] && [ ${b} != "TEK8-NX210V" ] && [ ${b} != "EVK" ];then
		    echo -e "### invalid baseboard\n\n"; usage
	    fi
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${m}" ] || [ -z "${b}" ]; then
	echo -e "### lack of option\n\n" && usage
elif ([ "${m}" == "Xavier-NX" ] && [ "${b}" == "EVK" ]) || ([ "${m}" == "Nano" ] && [ "${b}" == "TEK8-NVJETSON" ]);then
	echo -e "### invalid combination\n\n" && usage
fi

echo valid input: m=$m, b=$b

# install build require package
echo -ne "####install build require package\n"
sudo apt-get update -y
sudo apt-get install -y qemu-user-static bc kmod flex
sudo apt-get install -y gawk wget git git-core diffstat unzip texinfo gcc-multilib build-essential \
chrpath socat cpio python python3 python3-pip python3-pexpect \
python3-git python3-jinja2 libegl1-mesa pylint3 rsync bc bison \
xz-utils debianutils iputils-ping libsdl1.2-dev xterm \
language-pack-en coreutils texi2html file docbook-utils \
python-pysqlite2 help2man desktop-file-utils \
libgl1-mesa-dev libglu1-mesa-dev mercurial autoconf automake \
groff curl lzop asciidoc u-boot-tools libreoffice-writer \
sshpass ssh-askpass zip xz-utils kpartx vim screen

do_job
