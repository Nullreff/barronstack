class bungeecord {
  $userName = 'bungee'
  $home = "/home/${userName}"
  $fileUrl = 'http://ci.md-5.net/job/BungeeCord/lastSuccessfulBuild/artifact/proxy/target/BungeeCord.jar'
  $paths = [
    '/bin',
    '/sbin',
    '/usr/bin',
    '/usr/sbin',
    '/usr/local/bin',
    '/usr/local/sbin'
  ]

  user { $userName:
    ensure => 'present',
    shell  => '/bin/bash',
    home   => $home,
  }

  file { $home:
    ensure => 'directory',
    owner  => $userName,
    group  => $userName,
    mode   => '0774',
  }

  package { [
    'wget',
    'sudo',
    'vim',
    'screen',
    'openjdk-7-jre-headless',
  ]:
    ensure => 'installed',
  }

  exec { 'downloadBungeeCord':
    command => "wget ${fileUrl}",
    creates => "${home}/BungeeCord.jar",
    cwd     => $home,
    path    => $paths,
    user    => $userName,
    require => [
      Package['wget'],
      User[$userName],
      File[$home],
    ],
  }

  file { 'bungeeCordInit':
    ensure  => 'present',
    path    => '/etc/init.d/bungeecord',
    source  => 'puppet:///modules/bungeecord/service.sh',
    mode    => '0755',
    require => Exec['downloadBungeeCord'],
  }

  service { 'bungeecord':
    ensure  => 'running',
    enable  => true,
    require => [
      File['bungeeCordInit'],
      Exec['downloadBungeeCord'],
    ],
  }
}
