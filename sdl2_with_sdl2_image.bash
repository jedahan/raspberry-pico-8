#!/bin/bash
set -e

echo "You should read this script before running it"
exit 0

echo "Checking for and installing the latest version of piho"
piho >/dev/null || bash <(curl https://piho.sh) && piho init

echo "Creating a minimal raspbian image"
PIHO_IMAGE_NAME="sdl2_with_sdl2_image"
piho create "$PIHO_IMAGE_NAME"
piho run "$PIHO_IMAGE_NAME" bash -c "apt-get remove -y --purge scratch pypy-upstream sonic-pi freepats libraspberrypi-doc oracle-java8-jdk wolfram-engine && apt-get autoremove -y"
piho run "$PIHO_IMAGE_NAME" apt-get update
piho run "$PIHO_IMAGE_NAME" apt-get upgrade -y

echo "Installing sdl2"
SDL2_SRC="SDL2-2.0.3.tar.gz"
# instructions ripped from https://solarianprogrammer.com/2015/01/22/raspberry-pi-raspbian-getting-started-sdl-2/
piho run "$PIHO_IMAGE_NAME" apt-get install -y build-essential libfreeimage-dev libopenal-dev libpango1.0-dev libsndfile-dev libudev-dev libasound2-dev libjpeg8-dev libtiff5-dev libwebp-dev automake
WORKDIR=/home/pi
curl -OL https://www.libsdl.org/release/"$SDL2_SRC" && piho copy "$PIHO_IMAGE_NAME" "$SDL2_SRC" "$WORKDIR"
piho run "$PIHO_IMAGE_NAME" bash -c "cd $WORKDIR && tar xf $SDL2_SRC && mkdir ${SDL2_SRC%%.tar.gz}/build"
# build with OpenGL ES support only (fullscreen)
piho run "$PIHO_IMAGE_NAME" bash -c "cd ${WORKDIR}/${SDL2_SRC%%.tar.gz}/build && ../configure --host=armv7l-raspberry-linux-gnueabihf --disable-pulseaudio --disable-esd --disable-video-mir --disable-video-wayland --disable-video-x11 --disable-video-opengl && make -j4 && make install"
piho run "$PIHO_IMAGE_NAME" bash -c "rm -rf ${WORKDIR}/${SDL2_SRC%%.tar.gz}"

echo "Installing sdl2_image"
piho run "$PIHO_IMAGE_NAME" wget http://www.libsdl.org/projects/SDL_image/release/SDL2_image-2.0.0.tar.gz && tar zxvf SDL2_image-2.0.0.tar.gz && mkdir SDL2_image-2.0.0/build
piho run "$PIHO_IMAGE_NAME" bash -c "cd SDL2_image/build && ../configure && make -j4 && make install"
piho run "$PIHO_IMAGE_NAME" rm -rf /home/pi/SDL2_image

echo "Compiling and running test program"
piho copy "$PIHO_IMAGE_NAME" sdl2_image_test.cpp "$WORKDIR"
piho run "$PIHO_IMAGE_NAME" g++ -std=c++0x -Wall -pedantic sdl2_image_test.cpp -o sdl2_test `sdl2-config --cflags --libs` -lSDL2_image
