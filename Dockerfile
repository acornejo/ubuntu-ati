FROM acornejo/ubuntu-dev:latest
MAINTAINER Alex Cornejo <acornejo@gmail.com>

# install xserver (required for proper driver video install)
RUN apt-get update && apt-get install -q -y --force-yes --no-install-recommends x-window-system
# install kernel module utilities (required for video driver install)
RUN apt-get install -y module-init-tools

# copy over resources
ADD resources/ /tmp/

# install video driver
RUN test -f /tmp/video-driver-install && bash /tmp/video-driver-install || echo "*****ERROR***** skipped driver install"

# clean up resources
RUN rm -fr /tmp/*
