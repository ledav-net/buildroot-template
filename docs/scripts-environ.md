
- Buildroot's exported variables & examples:

BASE_DIR|O		o-foo_x86_64
BINARIES_DIR		o-foo_x86_64/images
BUILD_DIR		o-foo_x86_64/build
HOST_DIR		o-foo_x86_64/host
STAGING_DIR		o-foo_x86_64/host/*/sysroot
TARGET_DIR		o-foo_x86_64/target

BR2_CONFIG		o-foo_x86_64/.config
BR2_DL_DIR		../dl
BR2_EXTERNAL_FOO_DESC	Project's description
BR2_EXTERNAL_FOO_PATH	projects/foo
BR2_VERSION		ex: 2018.08-git
BR2_VERSION_FULL	ex: 2018.08-git-00777-g7bca2f1894

- Defined on top of each scripts:

MAINDIR			Buildroot main directory (git/svn repo)
SCRNAME			Actual running script's name
