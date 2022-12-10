ARG KERNEL_VERSION="6.0.11-300.fc37.x86_64"
ARG RPMFUSION_FREE="https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-37.noarch.rpm"
ARG RPMFUSION_NON_FREE="https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-37.noarch.rpm"

FROM fedora:37
ARG KERNEL_VERSION
ARG RPMFUSION_FREE
ARG RPMFUSION_NON_FREE

RUN dnf install -y $RPMFUSION_FREE $RPMFUSION_NON_FREE fedora-repos-archive && \
    dnf install -y mock xorg-x11-drv-nvidia{,-cuda} binutils kernel-devel-$KERNEL_VERSION kernel-$KERNEL_VERSION && \
    akmods --force

FROM ghcr.io/cgwalters/fedora-silverblue:37
# See https://pagure.io/releng/issue/11047 for final location

ARG KERNEL_VERSION
ARG RPMFUSION_FREE
ARG RPMFUSION_NON_FREE
# Copy kmod rpm from previous stage
COPY --from=0 /var/cache/akmods/nvidia /tmp/nvidia

COPY etc /etc

COPY ublue-firstboot /usr/bin

RUN rpm-ostree override remove firefox firefox-langpacks && \
    rpm-ostree install distrobox gnome-tweaks solaar && \
    rpm-ostree install gnome-shell-extension-appindicator yaru-theme && \
    rpm-ostree install ${RPMFUSION_FREE} ${RPMFUSION_NON_FREE} && \
    rpm-ostree install xorg-x11-drv-nvidia{,-cuda} kernel-${KERNEL_VERSION} && \
    rpm-ostree install /tmp/nvidia/*${KERNEL_VERSION}*.rpm && \
    rpm-ostree kargs --append=rd.driver.blacklist=nouveau --append=modprobe.blacklist=nouveau --append=nvidia-drm.modeset=1 \
    sed -i 's/#AutomaticUpdatePolicy.*/AutomaticUpdatePolicy=stage/' /etc/rpm-ostreed.conf && \
    systemctl enable rpm-ostreed-automatic.timer && \
    systemctl enable flatpak-automatic.timer && \
    rm -rf /var/* && rm -rf /tmp/nvidia && \
    rpm-ostree cleanup -m && \
    ostree container commit
