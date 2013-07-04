# Class: mark2::server
#
# Sets up a minecraft server container running on mark2
#
# Parameters:
#   [*title*] - Server name
#   [*user*] - The user name to run the server under
#   [*home*] -  The directory to run the server out of
#
# Actions:
#
# Requires:
#
# Sample Usage:
#   mark2::server { 'minecraft':
#     user => 'minecraft',
#     home => '/home/minecraft',
#   }
#
define mark2::server(
  $user = $title,
  $home = "/home/${title}",
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
    default: {
      fail('Unsuported operating system.')
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

  file { "/etc/init.d/${title}":
    ensure  => present,
    content => template('mark2/service.sh.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
  }

  service { $title:
    enable  => true,
    require => File["/etc/init.d/${title}"],
  }

  user { $user:
    ensure => present,
    shell  => '/bin/sh',
    home   => $home,
  }
}
