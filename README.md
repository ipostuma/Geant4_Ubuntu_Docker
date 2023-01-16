# Geant4_Ubuntu_Docker
Build an Ubuntu docker with VNC and NOVNC connection capabilities and with Geant4 installed

## Create docker

```docker build -t geant4_ubuntu_vnc_novnc .```

## Launch Docker

```docker run -d -p 5901:5901 -p 6901:6901 geant4_ubuntu_vnc_novnc```
