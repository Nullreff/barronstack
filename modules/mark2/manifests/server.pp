# Class: mark2::server
#
# Sets up a minecraft server container running on mark2
#
# Parameters:
#   [*server*] - Server name
#   [*user*] - The user name to run the server under
#   [*home*] -  The directory to run the server out of
#
# Actions:
#
# Requires:
#
# Sample Usage:
#   class { 'mark2::server':
#     server => 'minecraft',
#     user => 'minecraft',
#     home => '/home/minecraft',
#   }
#
class mark2::server(
  $server = 'minecraft',
  $user = 'minecraft',
  $home = '/home/minecraft',
) {
  $paths = ['/bin', '/sbin', '/usr/bin', '/usr/sbin']

  include 'mark2'

  case $::operatingsystem {
    centos, redhat: {
      $javaPackage = 'java-1.7.0-openjdk'
    }
    debian, ubuntu: {
      $javaPackage = 'openjdk-7-jre-headless'
    }
  }

  package { $javaPackage:
    ensure => installed,
  }

  file { $home:
    ensure => directory,
    owner  => $user,
    group  => $user,
  }

  file { "/etc/init.d/${server}":
    ensure  => present,
    content => template('mark2/service.sh.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  service { $server:
    enable  => true,
    require => File["/etc/init.d/${server}"],
  }

  user { $user:
    ensure => present,
    shell  => '/bin/sh',
    home   => $home,
  }
}
