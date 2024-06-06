
---------------------
## Buildroot template
---------------------
### Starting a new project from scratch, quick steps

1. Clone/copy this repo locally under the name of your new project.

2. Edit the 'makebr' script:
   - `BOARD=<board>`
     Set this as the default board for your project.  The corresponding
     `configs/<board>_defconfig` file must exist.  If not, copy your own
     there and create an appropriate `boards/<board>` structure or it will
     be done from the buildroot default configs for you when initializing. 
     If you are going to build a 'x86_64' image, it's already done as it's
     the one used by default in this repo.

   - `BUILDROOT_TAG="2018.11"`
     Select the version of buildroot you want to use. Leave it blank to use
     the master branch.

3. Go in the 'project' directory and edit the file `external.desc`:
   - Change the `name:` to `YOUR_PROJECT_NAME` (uppercases and underscores)
   - Shortly describe your project in the `description:` field

4. Start a first build: `./makebr`

You are done :-)
Good luck !!

Few more steps:

- Change this `README.md` file to something more appropriate for your project
- Take a look also in the `docs` directory...
- `./makebr --help` for a list of options
