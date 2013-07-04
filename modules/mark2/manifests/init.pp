# Class: mark2
#
# Sets up a mark2 hosting environment
# https://github.com/mcdevs/mark2/
#
# Parameters:
#   [*installPath*] - Where should mark2 be installed
#   [*repo*] - Git repository to use when installing
#
# Actions:
#
# Requires:
#
# Sample Usage:
#   class { 'mark2':
#       installPath => '/opt/mark2',
#   }
#
class mark2(
  $installPath = '/opt/mark2',
  $repo = 'https://github.com/mcdevs/mark2.git',
) {
  $paths = ['/bin', '/sbin', '/usr/bin', '/usr/sbin']

  $packages = [
    # installTwisted.sh
    'tar',
    'wget',

    # For downloading the source
    'git',

    # For building and installing
    'python',
    'python-dev',
    'python-pip',
    'build-essential',
  ]

  package { $packages:
    ensure => installed,
  }

  file { '/tmp/installTwisted.sh':
    ensure => present,
    source => 'puppet:///modules/mark2/installTwisted.sh',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/usr/bin/mark2':
    ensure => link,
    target => "${installPath}/mark2",
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/mark2':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
  }

  file { '/etc/mark2/mark2.properties':
    ensure  => present,
    source  => 'puppet:///modules/mark2/mark2.properties',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File['/etc/mark2'],
  }

  exec { 'installTwisted':
    command => 'sh /tmp/installTwisted.sh',
    creates => '/usr/local/bin/twistd',
    path    => $paths,
    require => [
      File['/tmp/installTwisted.sh'],
      Package['wget', 'tar', 'python'],
    ]
  }

  exec { 'installMark2':
    command => "git clone --depth=1 ${repo} ${installPath}",
    creates => $installPath,
    path    => $paths,
    require => Package['git'],
  }

  exec { 'installMark2Dependencies':
    command => 'pip install -r requirements.txt',
    cwd     => $installPath,
    path    => $paths,
    require => [
      Package['python-pip'],
      Exec['installMark2'],
    ]
  }
}
