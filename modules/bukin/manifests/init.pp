# Class: bukin
#
# Installs bukin - https://github.com/Nullreff/bukin
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#   include bukin
#
class bukin {
  case $::operatingsystem {
    centos, redhat: {
      $rubyDevPackage = 'ruby-devel'
    }
    debian, ubuntu: {
      $rubyDevPackage = 'ruby-dev'
    }
    default: {
      fail('Unsuported operating system.')
    }
  }

  package { [
    'make',
    'gcc',
    $rubyDevPackage,
  ]:
    ensure => installed,
  }

  package { 'bukin':
    ensure   => installed,
    provider => 'gem',
    require  => [
      Package['make'],
      Package['gcc'],
      Package[$rubyDevPackage],
    ],
  }
}
