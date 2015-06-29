#!/bin/bash
set -e

piho >/dev/null || ( echo "This script requires piho, install from https://github.com/xdissent/pihotenuse/" && exit ) 

WORKDIR=/home/pi

image="minimal"
piho ls | grep ^${image}\$ >/dev/null && echo "[1/4] ${image}: found, skipping creation" || {
  echo "[1/4] ${image}: Updated raspbian -cruft"
  piho create "$image"
  piho run $image apt-get remove -y --purge scratch pypy-upstream sonic-pi freepats libraspberrypi-doc oracle-java8-jdk wolfram-engine
  piho run $image apt-get autoremove -y
  piho run $image apt-get update
  piho run $image apt-get upgrade -y
  piho run $image apt-get install -y build-essential libfreeimage-dev libopenal-dev libpango1.0-dev libsndfile-dev libudev-dev libasound2-dev libjpeg8-dev libtiff5-dev libwebp-dev automake
}

image_old=$image && image="sdl2"
piho ls | grep ^${image}\$ >/dev/null && echo "[2/4] $image: found, skipping creation" || {
  echo "[2/4] ${image}: OpenGL ES-only version of SDL2 (v2.0.3)"
  piho clone $image_old $image
  SDL2_SRC="SDL2-2.0.3.tar.gz"
  [[ -f $SDL2_SRC ]] || curl -OL https://www.libsdl.org/release/"$SDL2_SRC" && piho copy "$image" "$SDL2_SRC" "$WORKDIR"
  piho run $image bash -c "cd $WORKDIR && tar xf $SDL2_SRC && cd ${SDL2_SRC%%.tar.gz} && mkdir -p build && cd build && ../configure --host=armv7l-raspberry-linux-gnueabihf --disable-pulseaudio --disable-esd --disable-video-mir --disable-video-wayland --disable-video-x11 --disable-video-opengl && make -j4 && make install"
  piho run $image rm -rf ${WORKDIR}/${SDL2_SRC%%.tar.gz}
}

image_old=$image && image="sdl2_image"
piho ls | grep ^${image}\$ >/dev/null && echo "[3/4] $image: found, skipping creation" || {
  echo "[3/4] ${image}: Adding sdl2_image"
  piho clone $image_old $image
  SDL2_IMAGE_SRC="SDL2_image-2.0.0.tar.gz"
  [[ -f $SDL2_IMAGE_SRC ]] || ( curl -OL http://www.libsdl.org/projects/SDL_image/release/$SDL2_IMAGE_SRC && piho copy "$image" "$SDL2_IMAGE_SRC" "$WORKDIR" )
  piho run $image bash -c "cd ${WORKDIR} && tar xf $SDL2_IMAGE_SRC && cd ${SDL2_IMAGE_SRC%%.tar.gz} && mkdir -p build && cd build && ../configure && make -j4 && make install"
  piho run $image rm -rf ${WORKDIR}/${SDL2_IMAGE_SRC%%.tar.gz}
}

image_old=$image && image="pico-8"
echo "[4/4] ${image}: compiling program"
piho rm $image && piho clone $old_image $image
piho copy "$image" `pwd`/sdl2_image_test.cpp `pwd`/img_test.png "$WORKDIR"
piho run $image bash -c 'cd /home/pi && g++ -std=c++0x -Wall -pedantic sdl2_image_test.cpp -o sdl2_test `sdl2-config --cflags --libs` -lSDL2_image'
