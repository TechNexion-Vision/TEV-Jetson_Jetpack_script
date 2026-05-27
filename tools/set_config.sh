#!/bin/bash -e

CONF_FILE="/boot/extlinux/extlinux.conf"

# get DEFAULT
current_default=$(grep -E "^DEFAULT" "$CONF_FILE" | awk '{print $2}')
echo "Current DEFAULT: $current_default"
echo

# get all LABEL
labels=($(grep -E "^LABEL" "$CONF_FILE" | awk '{print $2}'))

echo "Available LABELs:"
for i in "${!labels[@]}"; do
    echo "  [$i] ${labels[$i]}"
done
echo

# show input information
read -p "Enter index or label name to set as new DEFAULT (Enter to cancel): " input

if [[ -z "$input" ]]; then
    echo "Cancelled."
    exit 0
fi

# check number or string
if [[ "$input" =~ ^[0-9]+$ ]]; then
    if [ "$input" -ge 0 ] && [ "$input" -lt "${#labels[@]}" ]; then
        new_default=${labels[$input]}
    else
        echo "Invalid index!"
        exit 1
    fi
else
    # verify input label correctly
    if [[ " ${labels[*]} " =~ " $input " ]]; then
        new_default=$input
    else
        echo "Label not found!"
        exit 1
    fi
fi

echo "Setting DEFAULT to: $new_default"
sudo sed -i "s/^DEFAULT .*/DEFAULT $new_default/" "$CONF_FILE"

if [ $? -eq 0 ]; then
	echo "You should Reboot Device to enable $new_default."
	read -p "Do you want to reboot now?[y/N]" choice
	if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
		echo "Rebooting...."
		sudo reboot
	else
		echo "Reboot manually later."
	fi
fi