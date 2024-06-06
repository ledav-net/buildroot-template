    .
    ├── makebr

Master script.  Please double check the top of the `makebr` source for
possible finetunings...


    ├── boards
    │   └── x86_64
    │       ├── fs-overlay
    │       ├── linux-4.17.config
    │       ├── post-build-hook
    │       └── post-image-hook

Board specific configurations & finetunings.  What is there is required for
that specific hardware architechture like kernel config, modules, firmwares,
etc...

    ├── buildroot

The buildroot project cloned at init time. The idea is to never do direct
changes in there to ease the further updates process.

    ├── configs
    │   └── x86_64_defconfig

Holds the buildroot configurations of the different boards for your project.

    ├── o-x86_64

The output directory for the board where everything is done by buildroot.

    ├── project
    │   └── packages
    │       ├── bar
    │       │   ├── bar.mk
    │       │   └── Config.in
    │       ├── Config.in
    │       └── foo
    │           ├── Config.in
    │           └── foo.mk

Holds all the custom packages.  These will be accessible from `makebr
menuconfig` in the submenu "External options".  If a buildroot package need
to be finetuned/fixed, you can copy it there and make your changes. You can
then upstream it later if you want.

    ├── project
    │   ├── Config.in -> packages/Config.in
    │   ├── external.desc
    │   ├── external.mk
    │   ├── fs-overlay
    │   ├── local.mk
    │   ├── post-build-hook
    │   └── post-image-hook

This holds the project specific configurations, scripts & file-system
overlay. Everything here should focus only on the project itself. What is
hardware dependant should go in `/boards/<board>`

    └── scripts
        ├── include
        │   ├── colors
        │   └── log
        └── mkinitramfs.sh

Generic scripts to generate the initramfs or includes or whatever that could
be useful for your project from a generic point of view.
