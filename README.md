# rtw88-patched

Patched version of the Linux in-kernel `rtw88` driver for Realtek RTL8812AU, targeting passive monitoring use cases (e.g. [Kismet](https://www.kismetwireless.net/)).

## Problem

When Kismet channel-hops across VHT80 (80 MHz) 5 GHz channels, the rtw88 driver fires `WARN_ON(1)` in two TX power calculation functions on every single channel change — hundreds of times per minute:

```
WARNING: phy.c:2027 at rtw_get_tx_power_params [...] rtw88_core
WARNING: phy.c:2083 at rtw_get_tx_power_params [...] rtw88_core
```

The root cause: `rtw_phy_get_2g_tx_power_index` and `rtw_phy_get_5g_tx_power_index` only handle `RTW_CHANNEL_WIDTH_20` and `RTW_CHANNEL_WIDTH_40` in their bandwidth switch. `RTW_CHANNEL_WIDTH_80` hits the `default: WARN_ON(1)` case every hop. The driver falls through to the 20 MHz values anyway — it works, it just yells about it constantly.

## Changes

All changes are in `phy.c`:

| Location | Before | After |
|---|---|---|
| Bandwidth switch default (2.4 GHz) | `WARN_ON(1); fallthrough;` | `fallthrough;` |
| Bandwidth switch default (5 GHz) | `WARN_ON(1); fallthrough;` | `fallthrough;` |
| `err:` label in `rtw_get_tx_power_params` | `WARN(1, ...)` | `WARN_ONCE(1, ...)` |

The fallthrough to 20 MHz TX power values is a conservative and safe default — slightly lower TX power on VHT80 channels, irrelevant for passive monitoring where the adapter never transmits.

## Impact on active use

None in practice. The adapter works normally as a WiFi client or in AP mode. The only theoretical difference is marginally suboptimal TX power on 5 GHz 80 MHz channels — not measurable in real conditions.

## Installation via DKMS

DKMS automatically rebuilds the modules on kernel updates.

```bash
# Prerequisites
apt install dkms linux-headers-$(uname -r)

# Clone and install
git clone https://github.com/badyast/rtw88-patched.git /usr/src/rtw88-patched-1.0
dkms add rtw88-patched/1.0
dkms build rtw88-patched/1.0
dkms install rtw88-patched/1.0

# Reload driver
rmmod rtw88_8812au rtw88_8812a rtw88_88xxa rtw88_usb rtw88_core
modprobe rtw88_8812au
```

Verify:
```bash
dkms status
# rtw88-patched/1.0, 6.x.x, x86_64: installed

modinfo rtw88_8812au | grep filename
# filename: /lib/modules/.../updates/dkms/rtw88_8812au.ko.xz
```

## Tested on

- Kernel: `6.19.11+kali-amd64`
- Hardware: RTL8812AU (USB dual-band, `rtw88_8812au`)
- Use case: Kismet passive WiFi monitoring, channel hopping across 2.4 GHz + 5 GHz including VHT80

## Source

Extracted from `linux-source-6.19` (Kali Linux package `linux-source`). Only `phy.c` is modified; all other files are unmodified upstream kernel source.
