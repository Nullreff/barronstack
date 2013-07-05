#!/bin/sh

# Check if we're running as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root"
    exit 1
fi

# Debian
if [ -f /etc/debian_version ]; then
    if ! grep '7\.' /etc/debian_version >/dev/null; then
        echo "Unsuported Debian version, please use 7.x."
        exit 1
    fi
    echo "Detected Debian system, installing..."

    # Update all packages and install puppet and git
    apt-get update
    apt-get upgrade -y
    apt-get install -y puppet git

# CentOS/Redhat
elif [ -f /etc/redhat-release ]; then
    if ! grep ' 6\.' /etc/redhat-release >/dev/null; then
        echo "Unsuported CentOS/RedHat version, please use 6.x."
        exit 1
    fi
    echo "Detected CentOS/RedHat system, installing..."

    # Add RPM Forge source (used for htop and other utilities)
    rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt
    rpm -i http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el6.rf.`uname -i`.rpm

    # Add Puppet source
    rpm -i http://yum.puppetlabs.com/el/6/products/i386/puppetlabs-release-6-6.noarch.rpm

    # Update all packages and install puppet and git
    yum update -y
    yum upgrade -y
    yum install -y puppet git
else
    echo 'Unsuported operating system.  Email contact@barroncraft.com if you need help.'
    exit 1
fi

# Quick sanity check to make sure everything was installed properly
if ! command -v git >/dev/null 2>&1; then
    echo "There was an issue installing git..."
    exit 1
fi
if ! command -v puppet >/dev/null 2>&1; then
    echo "There was an issue installing puppet..."
    exit 1
fi

# Remove any existing files in the puppet directory
rm -rf /etc/puppet; mkdir /etc/puppet

# Clone the latest copy of the configuration into it
git clone https://github.com/Nullreff/barronstack.git /etc/puppet
cd /etc/puppet
git submodule init
git submodule update
cd -


# Then run the script to configure the server
puppet apply /etc/puppet/manifests/site.pp
