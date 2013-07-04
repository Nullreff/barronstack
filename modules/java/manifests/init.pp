# Class: java
#
# Installs java
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#   include 'java'
#
class java {
  case $::operatingsystem {
    centos, redhat: {
      $javaPackage = 'java-1.7.0-openjdk'
    }
    debian, ubuntu: {
      $javaPackage = 'openjdk-7-jre-headless'
    }
    default: {
      fail('Unsuported operating system.')
    }
  }

  package { $javaPackage:
    ensure => installed,
  }
}
