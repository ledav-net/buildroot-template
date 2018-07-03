.
├── board
│   └── x86_64
│       ├── fs-overlay
│       ├── linux-4.17.config
│       ├── post-build-hook
│       └── post-images-hook

Board specific configurations & finetunings. What is there is applied at the
end as a last step so that you can always activate specific configs for that
particular hardware like kernel modules, etc.

├── configs
│   ├── debug_build
│   └── project1_x86_64_defconfig

Holds the buildroot project and a debug file where you can put specific
defines that could be later used in the all the scripts/hooks to finetune
your build for debugging.

├── makebr

Master script. Better is to copy it to the name of a project. Like for
example makebr-project1 and setup that script for that specific project.
Please double check the top of the maklebr source for finetunings...

├── package
│   ├── bar
│   │   ├── bar.mk
│   │   └── Config.in
│   ├── Config.in
│   └── foo
│       ├── Config.in
│       └── foo.mk

Holds all the custom packages. These will be accessible from
"makebr menuconfig" in the submenu "External options"

├── patches
│   └── linux

Master place to put your patches for any packages/versions.

├── projects
│   └── project1
│       ├── board
│       ├── Config.in -> ../../package/Config.in
│       ├── external.desc
│       ├── external.mk
│       ├── fs-overlay
│       ├── local.mk
│       ├── post-build-hook
│       └── post-images-hook

This holds the project specific configurations, scripts & overlays.

└── scripts
    ├── include
    │   ├── colors
    │   └── log
    └── mkinitramfs.sh

Generic scripts to generate the initramfs or includes or whatever that could
be useful from a generic point of view.
