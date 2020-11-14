
---------------------
## Buildroot template
---------------------
### Starting a new project from scratch, quick steps

1. Clone/copy this repo locally under the name of your newt project and
   commit it.

2. Edit 'makebr':
   - `PROJECT=your_project_name`
     It must be the same as the defconfig you will use from buildroot
     (eg. `configs/your_project_name_x86_64_defconfig`).
   - `BUILDROOT_TAG="2018.11"`
     Select the version of buildroot you want to use. Leave it blank to use
     the master.

3. Go in the 'project' directory and
   - Move (git/svn mv) `project1` to `your_project_name`
   - Edit `your_project_name/external.desc`
     - Change the `name:` to `YOUR_PROJECT_NAME` in uppercase
     - Shortly describe your project in the `description:` field

4. Go back in the root of your project and initialize it: `./makebr --init`

5. Copy the defconfig you need from `buildroot/configs/`:
   - First by overwriting the default config
     `configs/project1_x86_64_defconfig`
   - Then move (svn/git mv) `configs/project1_x86_64_defconfig` to
     `configs/your_project_name_x86_64_defconfig`

6. Double check the presence of the `dl` directory in the root of your new
   project.  If you don't have a central download directory for all your
   buildroot projects, forget about this step.

   Otherwise, create a link name `dl` to the location of your central
   download directory.

7. Start a first build: `./makebr`

8. Change this `README.md` file to something more appropriate for your
   project. Take a look also in `docs` directory...


You are done :-)
Good luck !!
