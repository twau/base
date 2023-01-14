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
    kernel-$(cat /tmp/kernel-version.txt) kernel-devel-$(cat /tmp/kernel-version.txt) && \
    akmods --force
    
FROM ghcr.io/cgwalters/fedora-silverblue:37
# See https://pagure.io/releng/issue/11047 for final location
ARG OS_VERSION

# Copy kmod rpm and kernel-version from nvidia-builder
COPY --from=nvidia-builder /tmp/kernel-version.txt /tmp/kernel-version.txt
COPY --from=nvidia-builder /var/cache/akmods/nvidia /tmp/nvidia

COPY etc /etc
COPY ublue-firstboot /usr/bin

RUN wget https://copr.fedorainfracloud.org/coprs/kylegospo/gnome-vrr/repo/fedora-$(rpm -E %fedora)/kylegospo-gnome-vrr-fedora-$(rpm -E %fedora).repo -O /etc/yum.repos.d/_copr_kylegospo-gnome-vrr.repo
RUN rpm-ostree override replace --experimental --from repo=copr:copr.fedorainfracloud.org:kylegospo:gnome-vrr mutter gnome-control-center gnome-control-center-filesystem

RUN rpm-ostree install distrobox gnome-tweaks solaar && \
    rpm-ostree install gnome-shell-extension-appindicator yaru-theme && \
    rpm-ostree install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${OS_VERSION}.noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${OS_VERSION}.noarch.rpm && \
    rpm-ostree install xorg-x11-drv-nvidia{,-cuda} kernel-$(cat /tmp/kernel-version.txt) nvidia-vaapi-driver && \
    rpm-ostree install /tmp/nvidia/*$(cat /tmp/kernel-version.txt)*.rpm && \
    rpm-ostree install ffmpeg gstreamer1-plugin-openh264 gstreamer1-plugins-bad-free \
    gstreamer1-plugins-bad-freeworld gstreamer1-plugins-good gstreamer1-plugins-ugly && \
    sed -i 's/#AutomaticUpdatePolicy.*/AutomaticUpdatePolicy=stage/' /etc/rpm-ostreed.conf && \
    systemctl enable rpm-ostreed-automatic.timer && \
    systemctl enable flatpak-automatic.timer && \
    rm -rf /var/* && rm -rf /tmp/nvidia && \
    rm -f /etc/yum.repos.d/_copr_kylegospo-gnome-vrr.repo && \
    ostree container commit
