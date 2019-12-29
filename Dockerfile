FROM ubuntu:19.10
MAINTAINER Dale Glass <daleglass@gmail.com>

ARG linuxdeployqt_url=https://github.com/probonopd/linuxdeployqt/releases/download/6/linuxdeployqt-6-x86_64.AppImage
ARG appimagetool_url=https://github.com/AppImage/AppImageKit/releases/download/12/appimagetool-x86_64.AppImage
ARG jenkins_uid=983
ARG jenkins_gid=983
#ARG xz_source=https://tukaani.org/xz/xz-5.2.4.tar.xz



# This is a work in progress. The final intention is to build RPM packages of HiFi.
#
# Notes:
#
# Build fails on Fedora 30 due to statx calls failing with EPERM. 
# This is a docker issue: https://github.com/moby/moby/pull/36417
# Can be worked around by:
#     docker run --security-opt seccomp=statx_fixed.json
#
# To use strace inside the container, run with:
#     docker run --cap-add SYS_PTRACE


RUN sed -r -i 's/#\s*deb-src/deb-src/g' /etc/apt/sources.list
RUN apt update
RUN apt -y -u dist-upgrade


# Tools absolutely needed to build at all
RUN apt install -y build-essential qtbase5-dev libssl-dev python3 python3-pip git libnss3 libgstreamer-plugins-base1.0-0 cmake 


#RUN pip3 install cmake
#RUN ln -s /usr/local/bin/cmake /usr/bin


#RUN dnf install -y gcc gcc-c++ cmake git python qt5-devel qt5-qtwebengine-devel openssl-devel

# Installed by vcpkg, we should transition to these eventually
#  * glslang[core]:x64-linux
#    hifi-host-tools[core]:x64-linux
#  * hifi-scribe[core]:x64-linux
#  * spirv-tools[core]:x64-linux
#
#
#  * bullet3[core]:x64-linux
#  * draco[core]:x64-linux
#  * etc2comp[core]:x64-linux
#  * glm[core]:x64-linux
#    hifi-client-deps[core]:x64-linux
#  * hifi-deps[core]:x64-linux
#  * nlohmann-json[core]:x64-linux
#  * nvtt[core]:x64-linux
#  * openexr[core]:x64-linux
#  * sdl2[core]:x64-linux
#  * tbb[core]:x64-linux
#  * vulkanmemoryallocator[core]:x64-linux
#  * zlib[core]:x64-linux

#missing: glslang-dev spirv-tools-dev spirv-headers-dev spirv-tools 
RUN apt install -y libopenexr-dev zlib1g-dev libsdl2-dev


# Uncertain
RUN apt install -y libvulkan-dev  libquazip5-dev

# Additional tools not required for an actual build
# xz and pigz both can compress in parallel and are useful for making tarballs.
RUN apt install -y xz-utils pigz rsync libfuse2 wget patchelf openssh-client fuse

RUN wget "$linuxdeployqt_url" -O /usr/local/bin/linuxdeployqt
RUN wget "$appimagetool_url" -O /usr/local/bin/appimagetool

RUN chmod 755 /usr/local/bin/linuxdeployqt /usr/local/bin/appimagetool


# Qt
RUN apt build-dep -y qt5-default
RUN apt install -y build-essential git python gperf flex bison pkg-config libgl1-mesa-dev make g++ libdbus-glib-1-dev libnss3-dev 


# Missing
# * bullet3 - bullet, version 3? F30 only has 2.87
# * draco
# * etc2comp
# * SDL-mirror
# * nlohmann-json

# Missing, optional:
# * Leap Motion

# Optional debug tools
RUN apt install -y strace vim

### xz
# Xenial doesn't have a parallel capable xz. This is a problem for my 16 core build
# server.

#WORKDIR /tmp/xz
#RUN wget $xz_source
#RUN tar -xvf * && rm *.tar.xz
#RUN cd * && ./configure && make && make install
#RUN ldconfig

# Build with:
# mkdir build
# cd build
# cmake .. -DOpenGL_GL_PREFERENCE:STRING=GLVND

# We want to build stuff as a normal user
RUN useradd -m -u 2000  build

# Okay, this is a really ugly hack. Here's the problem: Jenkins runs the container under its own user ID,
# which for me happens to be 983.
#
# The AppImage packager really wants to know the username for some reason, so the user account has to exist.
# So as a temporary fix I'm just creating the user here. Future solutions might involve sudo, fakeroot, the
# AppImage packager, or just mass creating accounts, I'm not sure which.

RUN groupadd -g $jenkins_gid jenkins
RUN useradd -m -u $jenkins_uid -g $jenkins_gid  jenkins


USER build

CMD /bin/bash

