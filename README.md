# Single Purpose Linux distributions

A collection of scripts to deterministically configure, build and install
custom Linux distributions from scratch.

- `raspberry.sh` cross-compiled with [musl libc](https://www.musl-libc.org/):
  * `arm-linux-musleabihf` (32 bit): Raspberry Pi 1 and 1 B+
  * `aarch64-linux-musl` (64 bit): Raspberry Pi 3
- `debian.sh` configured to boot on [Google Compute Engine](https://cloud.google.com/compute/)
