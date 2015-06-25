#!/bin/bash
set -e

echo "You should read this script before running it"
#exit 0

PIHO_IMAGE_NAME="sdl2_with_sdl2_image"
WORKDIR=/home/pi
SDL2_SRC="SDL2-2.0.3.tar.gz"
SDL2_IMAGE_SRC="SDL2_image-2.0.0.tar.gz"

function pirun {
  piho run $PIHO_IMAGE_NAME $@
}
function pibash {
  piho run $PIHO_IMAGE_NAME bash -c \"$@\"
}

echo "Checking for and installing the latest version of piho"
piho >/dev/null || bash <(curl https://piho.sh) && piho init

echo "Creating a minimal raspbian image that can build from source"
piho create "$PIHO_IMAGE_NAME"
pirun apt-get remove -y --purge scratch pypy-upstream sonic-pi freepats libraspberrypi-doc oracle-java8-jdk wolfram-engine
pirun apt-get autoremove -y
pirun apt-get update
pirun apt-get upgrade -y
pirun apt-get install -y build-essential libfreeimage-dev libopenal-dev libpango1.0-dev libsndfile-dev libudev-dev libasound2-dev libjpeg8-dev libtiff5-dev libwebp-dev automake

echo "Installing sdl2 with OpenGL ES support only (fullscreen)"
[[ -f $SDL2_SRC ]] || ( curl -OL https://www.libsdl.org/release/"$SDL2_SRC" && piho copy "$PIHO_IMAGE_NAME" "$SDL2_SRC" "$WORKDIR" )
pibash "cd $WORKDIR && tar xf $SDL2_SRC && cd ${SDL2_SRC%%.tar.gz} && mkdir -p build && ../configure --host=armv7l-raspberry-linux-gnueabihf --disable-pulseaudio --disable-esd --disable-video-mir --disable-video-wayland --disable-video-x11 --disable-video-opengl && make -j4 && make install"
pirun rm -rf ${WORKDIR}/${SDL2_SRC%%.tar.gz}

echo "Installing sdl2_image"
[[ -f $SDL2_IMAGE_SRC ]] || ( curl -OL http://www.libsdl.org/projects/SDL_image/release/$SDL2_IMAGE_SRC && piho copy "$PIHO_IMAGE_NAME" "$SDL2_IMAGE_SRC" "$WORKDIR" )
pibash "cd ${WORKDIR} && tar xf $SDL2_IMAGE_SRC && cd ${SDL2_IMAGE_SRC%%.tar.gz} && mkdir -p build && cd build && ../configure && make -j4 && make install"
pirun rm -rf ${WORKDIR}/${SDL2_IMAGE_SRC%%.tar.gz}

echo "Compiling and running test program"
piho copy "$PIHO_IMAGE_NAME" sdl2_image_test.cpp img_test.png "$WORKDIR"
pibash "g++ -std=c++0x -Wall -pedantic ${WORKDIR}/sdl2_image_test.cpp -o sdl2_test `sdl2-config --cflags --libs` -lSDL2_image"
