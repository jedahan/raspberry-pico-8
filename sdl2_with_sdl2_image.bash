#!/bin/bash
set -e

piho >/dev/null || { echo "This script requires piho, install from https://github.com/xdissent/pihotenuse/"; exit; }

workdir=/home/pi

image="minimal"
piho ls | grep -q ^$image\$ && echo "[2/5] ${image}: found, skipping creation" || {
  echo "[1/5] $image: Updating raspbian and removing cruft"
  piho create "$image"
  piho run "$image" apt-get remove -y --purge scratch pypy-upstream sonic-pi freepats libraspberrypi-doc oracle-java8-jdk wolfram-engine
  piho run "$image" apt-get autoremove -y
  piho run "$image" apt-get update
  piho run "$image" apt-get upgrade -y
  piho run "$image" apt-get install -y build-essential libfreeimage-dev libopenal-dev libpango1.0-dev libsndfile-dev libudev-dev libasound2-dev libjpeg8-dev libtiff5-dev libwebp-dev automake

  echo "[2/5] $image: installing dispmanx_vnc for remote"
  piho run "$image" apt-get install -y gcc-4.7 g++-4.7 libvncserver-dev libconfig++-dev
  piho run "$image" sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.6 60 --slave /usr/bin/g++ g++ /usr/bin/g++-4.6
  piho run "$image" sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.7 40 --slave /usr/bin/g++ g++ /usr/bin/g++-4.7
  piho run "$image" sudo update-alternatives --config gcc
  piho run "$image" git clone https://github.com/patrikolausson/dispmanx_vnc.git
  piho run "$image" bash -c "cd dispmanx_vnc && make -j4 && make install"
}

image_old=$image; image="sdl2"
piho ls | grep -q ^$image\$ && echo "[3/5] $image: found, skipping creation" || {
  echo "[3/5] $image: OpenGL ES-only version of SDL2 (v2.0.3) + SDL2_image"
  piho clone "$image_old" "$image"
  sdl2_src="SDL2-2.0.3.tar.gz"
  [[ -f $sdl2_src ]] || curl -OL https://www.libsdl.org/release/"$sdl2_src"
  piho copy "$image" "$sdl2_src" "$workdir" || piho rm "$image"
  piho run "$image" bash -c "cd $workdir && tar xf $sdl2_src && cd ${sdl2_src%%.tar.gz} && mkdir -p build && cd build && ../configure --host=armv7l-raspberry-linux-gnueabihf --disable-pulseaudio --disable-esd --disable-video-mir --disable-video-wayland --disable-video-x11 --disable-video-opengl && make -j4 && make install" || piho rm "$image"
  piho run "$image" rm -rf ${workdir}/${sdl2_src%%.tar.gz}

  echo "[4/5] $image: Adding sdl2_image"
  sdl2_image_src="SDL2_image-2.0.0.tar.gz"
  [[ -f $sdl2_src ]] || curl -OL http://www.libsdl.org/projects/SDL_image/release/$sdl2_image_src
  piho copy "$image" "$sdl2_image_src" "$workdir"
  piho run "$image" bash -c "cd ${workdir} && tar xf $sdl2_image_src && cd ${sdl2_image_src%%.tar.gz} && mkdir -p build && cd build && ../configure && make -j4 && make install" || piho rm "$image"
  piho run "$image" rm -rf "$workdir"/"${sdl2_image_src%%.tar.gz}"
}

image_old=$image; image="pico8"
echo "[5/5] $image: compiling program"
piho rm "$image" && piho clone "$image_old" "$image"
piho copy "$image" "$PWD"/sdl2_image_test.cpp "$PWD"/img_test.png "$workdir"
piho run "$image" bash -c "cd /home/pi && g++ -std=c++0x -Wall -pedantic sdl2_image_test.cpp -o sdl2_test $(sdl2-config --cflags --libs) -lSDL2_image"
