#!/bin/bash
set -e

piho >/dev/null || { echo "This script requires piho, install from https://github.com/xdissent/pihotenuse/"; exit; }

workdir=/home/pi

image="minimal"
piho ls | grep -q ^$image\$ && echo "[1/4] ${image}: found, skipping creation" || {
  echo "[1/4] $image: Updated raspbian -cruft"
  piho create "$image"
  piho run "$image" apt-get remove -y --purge scratch pypy-upstream sonic-pi freepats libraspberrypi-doc oracle-java8-jdk wolfram-engine
  piho run "$image" apt-get autoremove -y
  piho run "$image" apt-get update
  piho run "$image" apt-get upgrade -y
  piho run "$image" apt-get install -y build-essential libfreeimage-dev libopenal-dev libpango1.0-dev libsndfile-dev libudev-dev libasound2-dev libjpeg8-dev libtiff5-dev libwebp-dev automake
}

image_old=$image; image="sdl2"
piho ls | grep -q ^$image\$ && echo "[2/4] $image: found, skipping creation" || {
  echo "[2/4] $image: OpenGL ES-only version of SDL2 (v2.0.3)"
  piho clone "$image_old" "$image"
  sdl2_src="SDL2-2.0.3.tar.gz"
  [[ -f $sdl2_src ]] || curl -OL https://www.libsdl.org/release/"$sdl2_src" && piho copy "$image" "$sdl2_src" "$workdir"
  piho run "$image" bash -c "cd $workdir && tar xf $sdl2_src && cd ${sdl2_src%%.tar.gz} && mkdir -p build && cd build && ../configure --host=armv7l-raspberry-linux-gnueabihf --disable-pulseaudio --disable-esd --disable-video-mir --disable-video-wayland --disable-video-x11 --disable-video-opengl && make -j4 && make install"
  piho run "$image" rm -rf ${workdir}/${sdl2_src%%.tar.gz}
}

image_old=$image; image="sdl2_image"
piho ls | grep -q ^$image\$ && echo "[3/4] $image: found, skipping creation" || {
  echo "[3/4] $image: Adding sdl2_image"
  piho clone "$image_old" "$image"
  sdl2_image_src="SDL2_image-2.0.0.tar.gz"
  [[ -f $sdl2_image_src ]] || ( curl -OL http://www.libsdl.org/projects/SDL_image/release/$sdl2_image_src && piho copy "$image" "$sdl2_image_src" "$workdir" )
  piho run "$image" bash -c "cd ${workdir} && tar xf $sdl2_image_src && cd ${sdl2_image_src%%.tar.gz} && mkdir -p build && cd build && ../configure && make -j4 && make install"
  piho run "$image" rm -rf "$workdir"/"${sdl2_image_src%%.tar.gz}"
}

image_old=$image; image="pico-8"
echo "[4/4] $image: compiling program"
piho rm "$image" && piho clone "$image_old" "$image"
piho copy "$image" "$PWD"/sdl2_image_test.cpp "$PWD"/img_test.png "$workdir"
piho run "$image" bash -c "cd /home/pi && g++ -std=c++0x -Wall -pedantic sdl2_image_test.cpp -o sdl2_test $(sdl2-config --cflags --libs) -lSDL2_image"
