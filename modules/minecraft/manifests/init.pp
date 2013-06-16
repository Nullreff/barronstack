# Class: minecraft
#
# Installs the basic requirements for running a barronstack server
#
# Parameters:
#   [*name*]   - Name that will be used to identify this server
#   [*config*] - The github link to the configuration to install
#
# Actions:
#
# Requires:
#
# Sample Usage:
#   class { 'minecraft':
#       name   => 'mc-dota',
#       config => 'barroncraft/mincraft-dota-config'
#   }
#
class minecraft($name, $config) {
    $user = $name
    $group = 'mc-editors'
    $server_path = "/home/${user}"
    $config_git = "git://github.com/${config}.git"
    $paths = ['/bin', '/sbin', '/usr/bin', '/usr/sbin']

    $packages = [
        'sudo',
        'screen',
        'git',
        'wget',
        'less',
        'rsync',
        'zip',
        'gzip',
        'openjdk-6-jre',
    ]

    $directories = [
        $server_path,
        "${server_path}/backups",
        "${server_path}/backups/worlds",
        "${server_path}/backups/server",
        "${server_path}/bin",
        "${server_path}/configs/${config}",
        "${server_path}/logs",
    ]

    package { $packages:
        ensure => installed,
    }

    service { $name:
        enable  => true,
        require => File["${name}_init"],
    }

    file { "${name}_init":
        ensure  => link,
        path    => "/etc/init.d/${name}",
        target  => "${server_path}/bin/minecraft.sh",
        mode    => '0755',
        require => File["${name}_script"],
    }

    file { "${name}_script":
        ensure => present,
        path   => "${server_path}/bin/minecraft.sh",
        source => 'puppet:///modules/minecraft/service.sh',
        owner  => $user,
        group  => $group,
        mode   => '0774',
    }

    file { $directories:
        ensure  => directory,
        owner   => $user,
        group   => $group,
        mode    => '0774',
    }

    file { "${server_path}/server":
        ensure => link,
        target => "configs/${config}",
        owner  => $user,
        group  => $group,
        mode   => '0744',
    }

    file { "${server_path}/.bashrc":
        ensure  => present,
        content => 'PATH=$PATH:~/bin',
        owner   => $user,
        group   => $group,
        mode    => '0644',
    }

    user { $user:
        ensure => present,
        shell  => '/bin/bash',
        home   => $server_path,
    }

    group { $group:
        ensure => present,
    }

    exec { "${name}_create_config":
        command => "git clone ${config_git} ${config}",
        cwd     => "${server_path}/configs",
        creates => "${server_path}/configs/${config}/.git",
        path    => $paths,
        user    => $user,
        require => [
            Package['git'],
            File["${server_path}/configs"]
        ],
    }

}
