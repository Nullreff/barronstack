class barronstack::server(
    $name = "mc-server", 
    $config = "vanilla-config"
){
    $user = $name
    $group = "mc-editors"
    $server_path = "/home/${user}"
    $configGit = "git://github.com/barroncraft/${config}.git"
    $paths = ["/bin", "/sbin", "/usr/bin", "/usr/sbin"]

    package { [ "sudo", 
                "screen", 
                "git", 
                "wget", 
                "less", 
                "rsync",
                "zip",
                "gzip",
                "openjdk-6-jre" ]: 
        ensure => installed, 
    }

    service { $name:
        enable  => true,
        require => File["${name}_init"],
    }

    file { "${name}_init":
        path   => "/etc/init.d/${name}",
        ensure => link,
        target => "${server_path}/bin/minecraft.sh",
        mode   => 755,
        require => File["${name}_script"],
    }

    file { "${name}_script":
        path   => "${server_path}/bin/minecraft.sh",
        ensure => present,
        source => "puppet:///modules/barronstack/minecraft.sh",
        owner  => $user,
        group  => $group,
        mode   => 774,
    }

    file { [ "${server_path}", 
             "${server_path}/backups", 
             "${server_path}/backups/worlds", 
             "${server_path}/backups/server", 
             "${server_path}/bin", 
             "${server_path}/configs", 
             "${server_path}/logs" ]:
        ensure  => "directory",
        owner   => $user,
        group   => $group,
        mode    => 774,
    }

    file { "${server_path}/server":
        ensure => link,
        target => "configs/${config}",
        owner  => $user,
        group  => $group,
        mode   => 744,
    }

    file { "${server_path}/.bashrc":
        content => 'PATH=$PATH:~/bin',
        ensure  => "present",
        owner   => $user,
        group   => $group,
        mode    => 644,
    }

    user { $user:
        ensure => present,
        shell  => "/bin/bash",
        home   => $server_path,
    }

    group { $group:
        ensure => "present",
    }

    exec { "${name}_create_config":
        command => "git clone ${configUrl} ${configName}",
        cwd     => "${server_path}/configs",
        creates => "${server_path}/configs/${configName}",
        path    => $paths,
        user    => "minecraft",
        require => [
            Package["git"],
            File["${server_path}/configs"]
       ],
    }
}
