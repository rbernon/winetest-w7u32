ARG BUILD=public

FROM dockurr/windows as private
ONBUILD COPY custom.iso /custom.iso
ONBUILD COPY drivers.txz /drivers.txz
ONBUILD COPY custom.xml /custom.xml

FROM dockurr/windows as public
ONBUILD COPY install.bat /oem/install.bat

FROM ${BUILD}
COPY startup.bat /oem/startup.bat
COPY autorun.bat /data/autorun.bat
COPY sudo.exe /data/sudo.exe
COPY configure.exe /data/configure.exe

ENV DISK_FLAGS="compression_type=zstd"
ENV DISK_FMT="qcow2"
ENV DISK_SIZE="16G"

ENV RAM_SIZE="4G"
ENV CPU_CORES="2"
ENV DISPLAY="disabled"
ENV ARGUMENTS="-device intel-hda -device hda-output -audio none"

RUN sed 's@rng0,bus=pcie.0@rng0@' -i /run/config.sh
RUN sed '/win81x64*/a"win81x86"* ) folder="w8.1/x86" \;\;' -i /run/install.sh
RUN sed '/win10x64*/a"win10x86"* ) folder="w10/x86" \;\;' -i /run/install.sh

ARG DISK_TYPE
ARG MACHINE
ARG BOOT_MODE

ENV DISK_TYPE=${DISK_TYPE}
ENV MACHINE=${MACHINE}
ENV BOOT_MODE=${BOOT_MODE}

CMD ["/bin/bash"]
