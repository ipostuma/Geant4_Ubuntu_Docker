# This Dockerfile is used to build an headles vnc image based on Debian

FROM ubuntu:22.04 as stage-0

ENV REFRESHED_AT 2022-10-13

LABEL io.k8s.description="Headless VNC Container with Xfce window manager, firefox and chromium" \
      io.k8s.display-name="Headless VNC Container based on Debian" \
      io.openshift.expose-services="6901:http,5901:xvnc" \
      io.openshift.tags="vnc, debian, xfce" \
      io.openshift.non-scalable=true

## Connection ports for controlling the UI:
# VNC port:5901
# noVNC webport, connect via http://IP:6901/?password=vncpassword
ENV DISPLAY=:1 \
    VNC_PORT=5901 \
    NO_VNC_PORT=6901
EXPOSE $VNC_PORT $NO_VNC_PORT

### Envrionment config
ENV HOME=/headless \
    TERM=xterm \
    STARTUPDIR=/dockerstartup \
    INST_SCRIPTS=/headless/install \
    NO_VNC_HOME=/headless/noVNC \
    DEBIAN_FRONTEND=noninteractive \
    VNC_COL_DEPTH=24 \
    VNC_RESOLUTION=1280x1024 \
    VNC_PW=vncpassword \
    VNC_VIEW_ONLY=false
WORKDIR $HOME

### Add all install scripts for further steps
ADD ./src/common/install/ $INST_SCRIPTS/
ADD ./src/debian/install/ $INST_SCRIPTS/

### Install some common tools
RUN $INST_SCRIPTS/tools.sh
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

### Install custom fonts
RUN $INST_SCRIPTS/install_custom_fonts.sh

### Install xvnc-server & noVNC - HTML5 based VNC viewer
RUN $INST_SCRIPTS/tigervnc.sh
RUN $INST_SCRIPTS/no_vnc.sh

### Install firefox and chrome browser
RUN $INST_SCRIPTS/firefox.sh
RUN $INST_SCRIPTS/chrome.sh

### Install xfce UI
RUN $INST_SCRIPTS/xfce_ui.sh
ADD ./src/common/xfce/ $HOME/

### configure startup
RUN $INST_SCRIPTS/libnss_wrapper.sh
ADD ./src/common/scripts $STARTUPDIR
RUN $INST_SCRIPTS/set_user_permission.sh $STARTUPDIR $HOME

USER 0

ENTRYPOINT ["/dockerstartup/vnc_startup.sh"]
CMD ["--wait"]

FROM stage-0 as finale

# Set the working directory
WORKDIR /sim

# Copy files from your host to your current working directory
COPY v11.1.0.tar.gz /sim

ARG DEBIAN_FRONTEND=noninteractive

RUN mkdir /sim/geant4 && \
    mkdir /sim/geant4/latest && \
    mkdir /sim/geant4/extract && \
    mkdir /sim/geant4/extract/build && \
    wget -c https://github.com/Geant4/geant4/archive/refs/tags/v11.1.0.tar.gz --output-document geant.tar.gz
    mv /sim/geant.tar.gz /sim/geant4/extract && \
    tar xzf /sim/geant4/extract/geant.tar.gz && \
    mv /sim/geant4-* /sim/geant4/extract/ && \
    cd /sim/geant4/extract/build && \
    apt-get update && \
    apt-get install libexpat1-dev libxmu-dev cmake build-essential qtbase5-dev qt5-qmake xorg openbox libglu1-mesa-dev freeglut3-dev mesa-common-dev -y && \
    cmake -DGEANT4_USE_OPENGL_X11=ON -DGEANT4_USE_QT=ON -DGEANT4_INSTALL_DATA=ON -DCMAKE_INSTALL_PREFIX=/sim/SW/geant4/latest/ ../geant4-*/ && \
    make -j6 && \
    make install 

USER 1000
