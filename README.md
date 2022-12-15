# base

A base image with a (mostly) stock Fedora Silverblue with the NVIDIA driver.

## Usage

Warning: This is an experimental feature and should not be used in production

    sudo rpm-ostree rebase --experimental ostree-unverified-registry:ghcr.io/twau/base:latest
  
## Features

- Start with a base Fedora Silverblue 37 image
- Adds the following packages to the base image:
  - distrobox, gnome-tweaks, solaar, gnome-shell-extension-appindicator and yaru-theme 
- Sets automatic staging of updates for the system
- Sets flatpaks to update twice a day

## Applications

- All applications installed per user instead of system wide, similar to openSUSE MicroOS, they are not on the base image. Thanks for the inspiration Team Green!
- Mozilla Firefox, Extension Manager, Libreoffice, Kopia, FontDownloader, Flatseal, and the Celluloid Media Player
- Core GNOME Applications installed from Flathub
  - GNOME Calculator, Calendar, Characters, Connections, Contacts, Evince, Firmware, Logs, Maps, NautilusPreviewer, TextEditor, Weather, baobab, clocks, eog, and font-viewer