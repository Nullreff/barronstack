#!/bin/sh
# Downloads and installs Twisted (http://twistedmatrix.com/)

# Temporary directory to extract and do work in
TWISTED=`mktemp -d`
trap "rm -rf $TWISTED" EXIT
cd $TWISTED

# Download and extract the latest version
wget https://pypi.python.org/packages/source/T/Twisted/Twisted-13.1.0.tar.bz2
tar jxf Twisted-13.1.0.tar.bz2
cd Twisted-13.1.0/

# Install it
python setup.py install

