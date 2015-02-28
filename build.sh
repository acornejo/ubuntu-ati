#!/bin/bash
set -e

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ $UID -eq 0 ]; then
  echo "Error: running as root, pleas run as a regular user."
  exit 1
fi

KERNEL_VERSION=$(uname -r | awk -F. '{printf("%d%03d", $1, $2)}')
if [ $KERNEL_VERSION -lt 3008 ]; then
    echo "Warning: You are using a kernel older than 3.8!!"
    echo "         for docker to function properly, you should have kernel 3.8 or higher"
    echo "         the building process may fail."
    echo
    echo "         press Ctrl-C to abort, press enter to continue..."
    read
fi

if ! hash docker >/dev/null; then
    echo "Error: docker not found. Please install it first."
    echo
    echo "   instructions at https://docs.docker.com/installation/"
    echo
    exit 1
fi

if ! id | grep docker >/dev/null; then
    echo "Error: $USER is not in the docker group." 
    echo
    echo "  To add yourself to a docker group:"
    echo
    echo "   sudo usermod -a -G docker $USER"
    echo
    exit 1
fi

if [ ! -f "resources/image-name" ]; then
    echo "Error: unable to find resource folder."
    exit 1
fi

IMAGE=$(cat resources/image-name)

ati_version=$(dmesg | dmesg | awk '/fglrx.*module/ { print $8  }')

if [ -z $ati_version ]; then
    echo "Must be run on linux with ati hardware!"
    # exit 1
fi

current_ati_packages=$(dpkg -l | awk '/fglrx/ {print $2}')

if [ -z "$current_ati_packages" ]; then
    echo "Must have installed the fglrx-* ati packages locally."
    # exit 1
fi

if [ -z "$(ls -A resources/ati/*.deb 2>/dev/null)"  ]; then
    apt-get -d --reinstall install $current_ati_packages
    cp /var/cache/apt/archives/fglrx* resources/ati
fi

rm -f resources/video-driver-install
for deb in resources/ati/*.deb; do
    echo dpkg-deb -x /tmp/ati/$(basename $deb) / >> resources/video-driver-install
done

echo "building $IMAGE image ..."
sudo docker build --rm=true -t $IMAGE $* .

echo $0 done.
