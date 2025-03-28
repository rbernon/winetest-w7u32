DOCKER := docker run $(shell tty -s && echo -it) -p 8006:8006 --device=/dev/kvm --device=/dev/net/tun --cap-add NET_ADMIN --stop-timeout 10 \
          -e COMMIT=Y -e DISPLAY=web

MACHINE_x86   := --build-arg=DISK_TYPE=ide --build-arg=MACHINE=pc --build-arg=BOOT_MODE=windows_legacy
MACHINE_amd64 := --build-arg=DISK_TYPE= --build-arg=MACHINE=q35 --build-arg=BOOT_MODE=windows

PART_x86   := MBR
PART_amd64 := GPT

empty :=
space := $(empty) $(empty)

define make-rules
build/$(1)/drivers.txz: virtio-win-0.1.266.iso | $$(shell mkdir -p build/$(1))
	mkdir -p build/$(1)/drivers
	env -C build/$(1)/drivers 7z x ../../../virtio-win-0.1.266.iso
	find build/$(1)/drivers/*/* -maxdepth 1 -type d -iname x86 -or -iname amd64 -or -iname arm64 | grep -v $(4)/$(3) | xargs rm -rf
	find build/$(1)/drivers -type d -empty -delete
	env -C build/$(1)/drivers tar cJf ../drivers.txz --owner=root:0 --group=root:0 --sort=name --mtime='1970-01-01' $$$$(ls build/$(1)/drivers)
	rm -rf build/$(1)/drivers

build/$(1)/custom.xml: src/unattend.xml | $$(shell mkdir -p build/$(1))
	sed -e 's@processorArchitecture="amd64"@processorArchitecture="$(3)"@g' \
	    -e 's@<InputLocale>0409:00000409</InputLocale>@<InputLocale>$$(subst $$(space),;,$$(LOCALE_$(1)))</InputLocale>@g' \
	    -e 's@<UILanguage>en-US</UILanguage>@<UILanguage>$$(firstword $$(LOCALE_$(1)))</UILanguage>@g' \
	    -e 's@<SystemLocale>en-US</SystemLocale>@<SystemLocale>$$(firstword $$(LOCALE_$(1)))</SystemLocale>@g' \
	    -e 's@<UserLocale>en-US</UserLocale>@<UserLocale>$$(firstword $$(LOCALE_$(1)))</UserLocale>@g' \
	    -e 's@<Key>/IMAGE/NAME</Key><Value>.*</Value>@<Key>/IMAGE/NAME</Key><Value>$$(EDITION_$(1))</Value>@g' \
	   -re 's@<!-- $$(EDITION_$(1)): (<ProductKey>.*) -->@\1@g' \
	    -e 's@<!--$$(PART_$(3))@@g; s@$$(PART_$(3))-->@@g' \
	    $$< | \
	  awk '/<RunSynchronous>/ { k=0 } /<FirstLogonCommands>/ { k=0 } /SynchronousCommand/ { sub("<Order>1</Order>", sprintf("<Order>%d</Order>", ++k)) } 1' >$$@

$(1).image: Dockerfile build/sudo.exe build/configure.exe build/startup.bat build/$(1)/custom.xml build/$(1)/drivers.txz
	$$(MAKE) -C /media/rbernon/LaCie/Downloads $$(IMAGE_$(1))/check
	cp $$(IMAGE_$(1)) build/$(1)/custom.iso
	cp build/sudo.exe build/$(1)/sudo.exe
	cp build/startup.bat build/$(1)/startup.bat
	cp build/configure.exe build/$(1)/configure.exe
	echo "start sudo configure.exe" >build/$(1)/autorun.bat
	docker build --build-arg=BUILD=private $$(MACHINE_$(3)) -f Dockerfile -t rbernon/private:$(1) build/$(1)
	docker push rbernon/private:$(1)
	touch $$@
all-image:: $(1).image

$(1).install: $(1).image
	$$(DOCKER) --cidfile=$$@ --entrypoint=/usr/bin/tini $(2) -- bash -c 'mkisofs -J -o /drivers.iso /data; /run/entry.sh'
	docker commit $$$$(cat $$@) rbernon/$(1):latest
	docker container rm $$$$(cat $$@)
all-install:: $(1).install
endef

# Windows 7 STARTER
# Windows 7 HOMEBASIC
# Windows 7 HOMEPREMIUM
# Windows 7 PROFESSIONAL
# Windows 7 ULTIMATE
EDITION_win7u-i386-en  := Windows 7 ULTIMATE
LOCALE_win7u-i386-en   := en-US
IMAGE_win7u-i386-en    := /media/rbernon/LaCie/Downloads/en_windows_7_ultimate_with_sp1_x86_dvd_u_677460.iso
$(eval $(call make-rules,win7u-i386-en,rbernon/winetest-windows:latest,x86,w7))

EDITION_win7u-amd64-en  := Windows 7 ULTIMATE
LOCALE_win7u-amd64-en   := en-US
IMAGE_win7u-amd64-en    := /media/rbernon/LaCie/Downloads/en_windows_7_ultimate_with_sp1_x64_dvd_u_677332.iso
$(eval $(call make-rules,win7u-amd64-en,rbernon/winetest-windows:latest,amd64,w7))

EDITION_win81-i386-en  := Windows 8.1 Pro
LOCALE_win81-i386-en   := en-US
IMAGE_win81-i386-en    := /media/rbernon/LaCie/Downloads/en_windows_8.1_with_update_x86_dvd_6051550.iso
$(eval $(call make-rules,win81-i386-en,rbernon/private:win81-i386-en,x86,w8.1))

EDITION_win81-amd64-en  := Windows 8.1 Pro
LOCALE_win81-amd64-en   := en-US
IMAGE_win81-amd64-en    := /media/rbernon/LaCie/Downloads/en_windows_8.1_with_update_x64_dvd_6051480.iso
$(eval $(call make-rules,win81-amd64-en,rbernon/winetest-windows:latest,amd64,w8.1))

EDITION_win10-1809-i386-en  := Windows 10 Pro
LOCALE_win10-1809-i386-en   := en-US
IMAGE_win10-1809-i386-en    := /media/rbernon/LaCie/Downloads/en_windows_10_consumer_edition_version_1809_updated_sept_2018_x86_dvd_0addd9ef.iso
$(eval $(call make-rules,win10-1809-i386-en,rbernon/winetest-windows:latest,x86,w10))

EDITION_win10-1809-amd64-en  := Windows 10 Pro
LOCALE_win10-1809-amd64-en   := en-US
IMAGE_win10-1809-amd64-en    := /media/rbernon/LaCie/Downloads/en_windows_10_consumer_edition_version_1809_updated_sept_2018_x64_dvd_5c2f3f9a.iso
$(eval $(call make-rules,win10-1809-amd64-en,rbernon/winetest-windows:latest,amd64,w10))

EDITION_win10-1809-amd64-fr  := Windows 10 Pro
LOCALE_win10-1809-amd64-fr   := fr-FR
IMAGE_win10-1809-amd64-fr    := /media/rbernon/LaCie/Downloads/fr_windows_10_consumer_editions_version_1809_updated_march_2019_x64_dvd_520b0ebd.iso
$(eval $(call make-rules,win10-1809-amd64-fr,rbernon/winetest-windows:latest,amd64,w10))

EDITION_win10-21h1-amd64-en  := Windows 10 Pro
LOCALE_win10-21h1-amd64-en   := en-US
IMAGE_win10-21h1-amd64-en    := /media/rbernon/LaCie/Downloads/en-us_windows_10_consumer_editions_version_21h1_updated_dec_2022_x64_dvd_c0e97d21.iso
$(eval $(call make-rules,win10-21h1-amd64-en,rbernon/winetest-windows:latest,amd64,w10))

EDITION_win11-24h2-amd64-en  := Windows 11 Pro
LOCALE_win11-24h2-amd64-en   := en-US
IMAGE_win11-24h2-amd64-en    := /media/rbernon/LaCie/Downloads/en-us_windows_11_consumer_editions_version_24h2_x64_dvd_1d5fcad3.iso
$(eval $(call make-rules,win11-24h2-amd64-en,rbernon/winetest-windows:latest,amd64,w11))

WINETEST64 := $(HOME)/Code/build-wine/build64/programs/winetest/x86_64-windows/winetest.exe
WINETEST32 := $(HOME)/Code/build-wine/build64/programs/winetest/i386-windows/winetest.exe
WINETEST := $(WINETEST32) $(subst /tests/,:,$(subst .ok,,$(filter %.ok,$(MAKECMDGOALS)))) $(subst /tests/check,,$(filter %/check,$(MAKECMDGOALS)))

%/tests: build/sudo.exe | $(shell mkdir -p build/tests) # %.install
	touch build/tests/winetest.report
	cp build/sudo.exe build/tests/sudo.Exe
	cp $(firstword $(WINETEST)) build/tests/winetest.exe
	echo "start sudo winetest.exe -q -o \\\\\\\\host.lan\\data\\winetest.report -t rbernon -m rbernon@codeweavers.com -i info $(wordlist 2,$(words $(WINETEST)),$(WINETEST))" >build/tests/autorun.bat
	$(DOCKER) --volume=$(CURDIR)/build/tests:/data --rm --entrypoint=/usr/bin/tini rbernon/$* -- bash -c 'mkisofs -J -o /drivers.iso /data; /run/entry.sh'
	grep -e "done" -e "Test failed" -e "Test succeeded" -e "tests executed.*failures" build/tests/winetest.report | grep -v -e 'done 0' -e ' 0 failures'

%.ok %/check: win7u-i386-en/tests
	echo $@ done

winetest-windows.install: Dockerfile build/sudo.exe build/configure.exe build/install.bat build/startup.bat | $(shell mkdir -p build/install)
	echo "start sudo configure.exe" >build/autorun.bat
	cp build/sudo.exe build/install/sudo.exe
	cp build/install.bat build/install/install.bat
	cp build/startup.bat build/install/startup.bat
	cp build/configure.exe build/install/configure.exe
	docker build -f Dockerfile $(MACHINE_amd64) -t rbernon/winetest-windows:latest build/install
	docker push rbernon/winetest-windows:latest
	touch $@

virtio-win-0.1.266.iso:
	wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.266-1/virtio-win-0.1.266.iso

build/%.exe: src/%.c | $(shell mkdir -p build)
	i686-w64-mingw32-gcc -o $@ $< -mwindows -municode

build/%: src/%
	cp -a $< $@

.SUFFIXES:
