ARG OS_VERSION=37

FROM ghcr.io/cgwalters/fedora-silverblue:37 as kernel-query
#We can't use the `uname -r` as it will pick up the host kernel version
RUN rpm -qa kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' > /tmp/kernel-version.txt

FROM fedora:37 as nvidia-builder
ARG OS_VERSION
COPY --from=kernel-query /tmp/kernel-version.txt /tmp/kernel-version.txt

RUN dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$OS_VERSION.noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$OS_VERSION.noarch.rpm fedora-repos-archive && \
    dnf install -y mock xorg-x11-drv-nvidia{,-cuda} binutils \
    kernel-$(cat /tmp/kernel-version.txt) kernel-modules-$(cat /tmp/kernel-version.txt) kernel-devel-$(cat /tmp/kernel-version.txt) && \
    akmods --force
    
FROM ghcr.io/cgwalters/fedora-silverblue:37
# See https://pagure.io/releng/issue/11047 for final location
ARG OS_VERSION

# Copy kmod rpm and kernel-version from nvidia-builder
COPY --from=nvidia-builder /tmp/kernel-version.txt /tmp/kernel-version.txt
COPY --from=nvidia-builder /var/cache/akmods/nvidia /tmp/nvidia

COPY etc /etc
COPY ublue-firstboot /usr/bin

RUN rpm-ostree install distrobox gnome-tweaks solaar && \
    rpm-ostree install gnome-shell-extension-appindicator yaru-theme && \
    rpm-ostree install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${OS_VERSION}.noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${OS_VERSION}.noarch.rpm && \
    rpm-ostree install xorg-x11-drv-nvidia{,-cuda} kernel-$(cat /tmp/kernel-version.txt) nvidia-vaapi-driver && \
    rpm-ostree install /tmp/nvidia/*$(cat /tmp/kernel-version.txt)*.rpm && \
    sed -i 's/#AutomaticUpdatePolicy.*/AutomaticUpdatePolicy=stage/' /etc/rpm-ostreed.conf && \
    systemctl enable rpm-ostreed-automatic.timer && \
    systemctl enable flatpak-automatic.timer && \
    rm -rf /var/* && rm -rf /tmp/nvidia && \
    rpm-ostree cleanup -m && \
    ostree container commit
