#!/bin/sh
# Top level configuration script for the MusicKit. This is used to bootstrap the configure generator. You
# will typically want to run this if you are checking the source straight out of the
# repository or the distributed configure script is too old.

autoconf
./configure
make
