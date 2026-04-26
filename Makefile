# DKMS Makefile for patched rtw88 (8812AU)
KVER  ?= $(shell uname -r)
KDIR  ?= /lib/modules/$(KVER)/build

obj-m += rtw88_core.o
rtw88_core-y := main.o mac80211.o util.o debug.o tx.o rx.o mac.o phy.o \
                coex.o efuse.o fw.o ps.o sec.o bf.o sar.o regd.o \
                wow.o led.o

obj-m += rtw88_88xxa.o
rtw88_88xxa-objs := rtw88xxa.o

obj-m += rtw88_8812a.o
rtw88_8812a-objs := rtw8812a.o rtw8812a_table.o

obj-m += rtw88_8812au.o
rtw88_8812au-objs := rtw8812au.o

obj-m += rtw88_usb.o
rtw88_usb-objs := usb.o

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
