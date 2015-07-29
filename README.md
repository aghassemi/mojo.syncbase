# Ether

This project exposes Syncbase as a Mojo service.

Read the [architecture proposal].

## Initial Mojo setup

You must have the Mojo repo in $MOJO_DIR.

This section only needs to be run once.

See the [mojo readme] for more comprehensive instructions.

### Install Mojo prereqs

1. Install [depot tools].
2. Install [Goma][goma].
3. Put the following in your .bashrc:

    # NOTE: Actual locations depend on where you installed depot_tools and goma.
    export PATH=${PATH}:${HOME}/dev/depot_tools
    export GOMA_DIR=${HOME}/goma

    export MOJO_DIR=${HOME}/mojo

### Download Mojo repo

    $ mkdir $MOJO_DIR && cd $MOJO_DIR

    # NOTE: This step takes about 10 min.
    $ fetch mojo --target_os=android,linux

    # NOTE: This step also takes about 10 min.  Furthermore, the script uses
    # 'sudo', so you will need to enter your password.
    $ cd src && ./build/install-build-deps-android.sh

## Update Mojo and compile resources

This updates the Mojo repo to HEAD, and builds the Mojo resources needed to
compile Ether.

Run this while you grab your morning coffee.

1. Start by updating the repo.

    $ cd $MOJO_DIR/src
    $ git checkout master
    $ git pull
    $ gclient sync

2. Compile for Linux.  Built resources will be in $MOJO_DIR/src/out/Debug

    $ ./mojo/tools/mojob.py gn
    $ ./mojo/tools/mojob.py build # NOTE: This can take up to 10 minutes.

3. Compile for Android.  Built resources will be in $MOJO_DIR/src/out/android_Debug

    $ ./mojo/tools/mojob.py gn --android
    $ ./mojo/tools/mojob.py build --android # NOTE: This can take up to 10 minutes.

[architecture proposal]: https://docs.google.com/document/d/1TyxPYIhj9VBCtY7eAXu_MEV9y0dtRx7n7UY4jm76Qq4/edit
[depot tools]: http://www.chromium.org/developers/how-tos/install-depot-tools
[goma]: https://sites.google.com/a/google.com/goma/how-to-use-goma/how-to-use-goma-for-chrome-team
[mojo readme]: https://github.com/domokit/mojo/blob/master/README.md
