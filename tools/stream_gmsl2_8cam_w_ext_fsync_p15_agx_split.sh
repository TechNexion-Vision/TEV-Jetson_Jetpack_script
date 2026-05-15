#!/bin/bash -e

BUS_ARR="9 9 10 10 11 11 12 12"						# i2c bus
# DES_ARR="0x4c 0x4c 0x4c 0x4c"						# DES_0 ~ DES_1
SER_ARR="0x41 0x42 0x41 0x42 0x41 0x42 0x41 0x42"	# SER_0 ~ SER_7
CAM_ARR="0x3d 0x3e 0x3d 0x3e 0x3d 0x3e 0x3d 0x3e"	# CAM_0 ~ CAM_7
DES_IDX="0 0 1 1 2 2 3 3"

###

echo "[   INFO ] Set PWM 30 Hz at pin 15 of orin nano 40-pin header"
PWM_PATH="/sys/class/pwm/pwmchip0"
if [ ! -d "$PWM_PATH/pwm0" ]; then
	echo "[   INFO ] Export pwm0"
	echo 0 > "$PWM_PATH/export"
	sleep 0.1
else
	echo 0 > $PWM_PATH/pwm0/enable
fi

sleep 0.1
echo 33333333 > /sys/class/pwm/pwmchip0/pwm0/period
echo 16666666 > /sys/class/pwm/pwmchip0/pwm0/duty_cycle
sleep 0.1
echo 1 > /sys/class/pwm/pwmchip0/pwm0/enable

###

# Detect existing cameras (from tevs subdev)
EXIST_IDX=""
for namefile in /sys/class/video4linux/v4l-subdev*/name; do
	name=$(cat "$namefile")
	case "$name" in
		tevs*)
			echo "[   INFO ] Found cameras: $name"
			# tevs 9-0039 -> extract last bus 9
			bus=$(echo "$name" | awk '{print $2}' | cut -d'-' -f1)
			# tevs 9-0039 -> extract last hex 0039
			hexaddr=$(echo "$name" | awk '{print $2}' | cut -d'-' -f2)
			i2caddr=$(printf "%d" "0x$hexaddr")

			idx=0
			for cam in $CAM_ARR; do
				cam_dec=$(printf "%d" "$cam")
				cam_bus=$(echo "$BUS_ARR" | awk "{ print \$$((idx+1)) }")

				if [ "$bus" -eq "$cam_bus" ] && [ "$i2caddr" -eq "$cam_dec" ]; then
					EXIST_IDX="$EXIST_IDX $idx"
				fi

				idx=$((idx+1))
			done
			;;
	esac
done

if [ -z "$EXIST_IDX" ]; then
	echo "[   INFO ] No tevs cameras detected. Exiting."
	exit 0
fi

# normalize leading spaces
EXIST_IDX=$(echo "$EXIST_IDX" | sed -e 's/^ *//' -e 's/  */ /g')
EXIST_IDX=$(printf "%s\n" $EXIST_IDX | sort -n | tr '\n' ' ' | sed 's/ $//')
echo "[   INFO ] Found cameras at index: [$EXIST_IDX]"

DES_EXPECT=""
DES_STARTED=""
DES_RESET=""
for idx in $EXIST_IDX; do
	des=$(echo "$DES_IDX" | awk "{ print \$$((idx+1)) }")
	DES_EXPECT="$DES_EXPECT $des"
done
DES_EXPECT=$(echo "$DES_EXPECT" | sed -e 's/^ *//' -e 's/  */ /g')
echo "[   INFO ] Expected cameras at deserializer: [$DES_EXPECT]"

# counter camera in every deserializer
DES_LIST=$(printf "%s\n" $DES_EXPECT | sort -n | uniq)

# GUI display settings
export XAUTHORITY=/home/ubuntu/.Xauthority
export DISPLAY=$(w| tr -s ' '| cut -d ' ' -f 3|grep :)

RES=$(xrandr |grep \* |head -1|tr -s ' '| cut -d ' ' -f 2)
# RES="4480x1440"
RES_X=$(echo $RES|cut -d 'x' -f 1)
RES_Y=$(echo $RES|cut -d 'x' -f 2)
TOOLBAR_W=72
TOOLBAR_H=64

SINK_SIZE_X=$(( (RES_X - TOOLBAR_W) / 4 ))
SINK_SIZE_Y=$(( (RES_Y - TOOLBAR_H) / 4 ))

SINK_POS_X_0=$(( SINK_SIZE_X * 0 + TOOLBAR_W ))
SINK_POS_X_1=$(( SINK_SIZE_X * 1 + TOOLBAR_W ))
SINK_POS_X_2=$(( SINK_SIZE_X * 2 + TOOLBAR_W ))
SINK_POS_X_3=$(( SINK_SIZE_X * 3 + TOOLBAR_W ))

SINK_POS_Y_0=0
SINK_POS_Y_1=$(( SINK_SIZE_Y * 1 + TOOLBAR_H ))

# VIDEO format setting
VIDEO_WIDTH=640
VIDEO_HEIGHT=480

# Stream only EXISTING cameras
CAM_COUNT=0
for idx in $EXIST_IDX; do
	cam_addr=$(echo "$CAM_ARR" | awk "{ print \$$((idx+1)) }")
	cam_bus=$(echo "$BUS_ARR" | awk "{ print \$$((idx+1)) }")

	echo "[   INFO ] Camera $idx stream (bus $cam_bus, addr $cam_addr, /dev/video$CAM_COUNT)"

	cam_ver_year=$(i2ctransfer -f -y $cam_bus w2@$cam_addr 0x30 0x00 r1 | sed 's/0x//g')
	cam_ver_month=$(i2ctransfer -f -y $cam_bus w2@$cam_addr 0x30 0x01 r1 | sed 's/0x//g')
	cam_ver_rev=$(i2ctransfer -f -y $cam_bus w2@$cam_addr 0x30 0x02 r1 | sed 's/0x//g')
	cam_ver_build=$(i2ctransfer -f -y $cam_bus w2@$cam_addr 0x30 0x03 r1 | sed 's/0x//g')

	# layout: column = idx % 4, row = idx / 4
	col=$(( CAM_COUNT % 4 ))
	row=$(( CAM_COUNT / 4 ))

	case "$col" in
		0) winx=$SINK_POS_X_0 ;;
		1) winx=$SINK_POS_X_1 ;;
		2) winx=$SINK_POS_X_2 ;;
		3) winx=$SINK_POS_X_3 ;;
		*) winx=$SINK_POS_X_0 ;;
	esac

	case "$row" in
		0) winy=$SINK_POS_Y_0 ;;
		1) winy=$SINK_POS_Y_1 ;;
		*) winy=$SINK_POS_Y_0 ;;
	esac

	DISPLAY=:0 gst-launch-1.0 nvv4l2camerasrc device=/dev/video$CAM_COUNT ! \
	"video/x-raw(memory:NVMM), format=UYVY, width=$VIDEO_WIDTH, height=$VIDEO_HEIGHT" ! \
	queue ! nvvidconv ! "video/x-raw, format=NV12" ! \
	textoverlay text="CAM$idx $(printf "%d" 0x$cam_ver_year).$(printf "%d" 0x$cam_ver_month).$(printf "%d" 0x$cam_ver_rev).$(printf "%d" 0x$cam_ver_build)" \
	valignment=top halignment=left font-desc="Sans, 24" ! \
	queue ! nvvidconv ! "video/x-raw(memory:NVMM), format=NV12, width=$SINK_SIZE_X, height=$SINK_SIZE_Y" ! \
	nv3dsink window-width=$SINK_SIZE_X window-height=$SINK_SIZE_Y \
	window-x=$winx window-y=$winy sync=false --no-position &

	CAM_COUNT=$((CAM_COUNT+1))
	sleep 1

	des_idx=$(echo "$DES_IDX" | awk "{ print \$$((idx+1)) }")

	# record camera stream in deserializer
	DES_STARTED="$DES_STARTED $des_idx"

	# counter camera number in deserializer
	started_cnt=$(printf "%s\n" $DES_STARTED | grep -c "^$des_idx$")

	# counter expected camera in deserializer
	expected_cnt=$(printf "%s\n" $DES_EXPECT | grep -c "^$des_idx$")

	# check counter nubmer equal expected nubmer or not
	if [ "$started_cnt" -eq "$expected_cnt" ] && \
	! echo " $DES_RESET " | grep -q " $des_idx "; then

		echo "[   INFO ] All cameras of DES $des_idx started, reset serializer"

		for j in $EXIST_IDX; do
			des_j=$(echo "$DES_IDX" | awk "{ print \$$((j+1)) }")
			if [ "$des_j" = "$des_idx" ]; then
				ser_addr=$(echo "$SER_ARR" | awk "{ print \$$((j+1)) }")
				ser_bus=$(echo "$BUS_ARR" | awk "{ print \$$((j+1)) }")

				i2ctransfer -f -y "$ser_bus" w3@"$ser_addr" 0x03 0x30 0x48
				# i2ctransfer -f -y "$ser_bus" w3@"$ser_addr" 0x03 0x30 0x40
			fi
		done

		for j in $EXIST_IDX; do
			des_j=$(echo "$DES_IDX" | awk "{ print \$$((j+1)) }")
			if [ "$des_j" = "$des_idx" ]; then
				ser_addr=$(echo "$SER_ARR" | awk "{ print \$$((j+1)) }")
				ser_bus=$(echo "$BUS_ARR" | awk "{ print \$$((j+1)) }")

				# i2ctransfer -f -y "$ser_bus" w3@"$ser_addr" 0x03 0x30 0x48
				i2ctransfer -f -y "$ser_bus" w3@"$ser_addr" 0x03 0x30 0x40
			fi
		done

		DES_RESET="$DES_RESET $des_idx"
	fi
done
