#!/bin/bash

ZOEF_SRC_DIR=/usr/local/src/zoef

# Install dependencies
sudo apt install -y git curl binutils libusb-1.0-0

# Install arduino-cli
# We need to install version 0.13.0. From version 0.14.0 on a check is done on the hash of the packages,
# while the community version of the STM (see below) needs insecure packages.
curl https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sudo BINDIR=/usr/local/bin sh -s 0.13.0
sudo chown -R zoef:zoef /home/zoef/.arduino15

# Install arduino avr support (for nano)
arduino-cli -v core update-index --additional-urls https://raw.githubusercontent.com/koendv/stm32duino-raspberrypi/master/BoardManagerFiles/package_stm_index.json
arduino-cli -v core install arduino:avr

# Install STM32 support. Currently not supported by stm32duino (see https://github.com/stm32duino/Arduino_Core_STM32/issues/708), but there is already
# a community version (https://github.com/koendv/stm32duino-raspberrypi). TODO: go back to stm32duino as soon as it is merged into stm32duino.
arduino-cli -v core install STM32:stm32 --additional-urls https://raw.githubusercontent.com/koendv/stm32duino-raspberrypi/master/BoardManagerFiles/package_stm_index.json

# Fix for community STM32 (TODO: make version independant)
sed -i 's/dfu-util\.sh/dfu-util\/dfu-util/g' /home/zoef/.arduino15/packages/STM32/tools/STM32Tools/1.4.0/tools/linux/maple_upload
ln -s /home/zoef/.arduino15/packages/STM32/tools/STM32Tools/1.4.0/tools/linux/maple_upload /home/zoef/.arduino15/packages/STM32/tools/STM32Tools/1.4.0/tools/linux/maple_upload.sh
sudo cp /home/zoef/.arduino15/packages/STM32/tools/STM32Tools/1.4.0/tools/linux/45-maple.rules /etc/udev/rules.d/45-maple.rules
sudo service udev restart

# Install libraries needed by FirmataExpress
arduino-cli lib install "Ultrasonic"
arduino-cli lib install "Stepper"
arduino-cli lib install "Servo"
arduino-cli lib install "DHTNEW"

# Install our own arduino libraries
ln -s $ZOEF_SRC_DIR/zoef-arduino-libraries/OpticalEncoder /home/zoef/Arduino/libraries

# Install Blink example code
mkdir /home/zoef/arduino_project/Blink
ln -s $ZOEF_SRC_DIR/zoef_web_interface/Blink.ino /home/zoef/arduino_project/Blink

# Already build all versions so only upload is needed
./run_arduino.sh build Telemetrix4Arduino
./run_arduino.sh build_nano Telemetrix4Arduino
./run_arduino.sh build_nano_old Telemetrix4Arduino
./run_arduino.sh build_uno Telemetrix4Arduino

# Add zoef to dialout
sudo adduser zoef dialout

# By default, armbian has ssh login for root enabled with password 1234.
# The password need to be set to zoef_zoef so users can use the
# Arduino IDE remotely. 
# TODO: when the Arduino IDE also supports ssh for non-root-users
# this has to be changed
echo -e "zoef_zoef\nzoef_zoef" | sudo passwd root

# Enable tuploading from remote IDE
sudo ln -s $ZOEF_SRC_DIR/zoef_arduino/run-avrdude /usr/bin
sudo bash -c 'echo "zoef ALL = (root) NOPASSWD: /usr/local/bin/arduino-cli" >> /etc/sudoers'
