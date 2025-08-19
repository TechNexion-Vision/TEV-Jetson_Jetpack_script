![video_orin-Banner-TEK(1) >](https://github.com/TechNexion-Vision/TEV-Jetson_Jetpack_script/assets/83322668/f699fae3-22a0-4eb0-9334-023286b953ca)

This script contains a complete system package that enables your Jeston Jetpack to directly support TechNexion embedded vision devices.

## Product page:

[TEK6040-ORIN-NANO](https://www.technexion.com/products/embedded-computing/aivision/tek6040-orin-nano/)

[TEK6100-ORIN-NX](https://www.technexion.com/products/embedded-computing/aivision/tek6100-orin-nx/)

## Full instruction:
[Technexion Portal](https://developer.technexion.com/docs/embedded-software/linux/nvidia-jetpack/usage-guides/jetpack620/host-environment-setting)

## 1. Prepare ubuntu environment
Download Ubuntu 20.04/ 22.04 iso file from [ubuntu web site](https://ubuntu.com/download/desktop).

This script supports native Ubuntu or Ubuntu VM.

## 2. Create TN Jetpack base on your device.
### Prepare git command in your ubuntu
```Bash
$ sudo apt-get update -y
$ sudo apt-get install git -y
```

### Create the nvidia workspace folder
```Bash
# Select one folder for Nvidia workspace
$ cd <workspace>
$ mkdir <nvidia_folder>
```

### Download the TN Jetpack
```Bash
$ git clone https://github.com/TechNexion-Vision/TEV-Jetson_Jetpack_script.git

# Copy script and conf file to your work folder
$ cp -rv TEV-Jetson_Jetpack_script/technexion_jetpack_download.sh <nvidia_folder>
$ cp -rv TEV-Jetson_Jetpack_script/*conf <nvidia_folder>
$ cd <nvidia_folder>
```
### run the script
```Bash
# Run the script to download Jetpack and Technexion sources
# example:
$ ./technexion_jetpack_download.sh -b TEK6100-ORIN-NX
```

```bash
# you can check all the option once you enter the wrong option.
$ ./technexion_jetpack_download.sh 
download the Technexion Jetpack -b <baseboard>
-b: baseboard <TEK6040-ORIN-NANO/ TEK6100-ORIN-NX>

Jetson Orin series:
TEK6040-ORIN-NANO| TEK6100-ORIN-NX

-t: tag for sync code:
r36.4.ga

--qspi-only: do not create/ flash rootfs, for qspi image only

flash options: <--flash-only/--build-flash/--no-flash>
```

## 3. Flash demo image from TEV-Jetpack

### Enter Recovery mode
1. **Connect** to computer via **M-USB1**.
2. Press **'Recovery**' button and '**Reset**' button **at the same time**.
3. Release '**Reset**' button.
4. Release '**Recovery**' button.
5. Check wether the device is connected.
```Bash
$ lsusb
Bus 001 Device 012: ID 0955:7e19 NVIDIA Corp. APX
```

### Flash demo image from L4T
```Bash
# Use flash option `--flash-only`
$ ./technexion_jetpack_download.sh -b <baseboard> --flash-only
```
# Want for more guide ? 
click here !! [Technexion Portal](https://developer.technexion.com/docs/embedded-software/linux/nvidia-jetpack/usage-guides/jetpack620/)
