class mysql::config
{
  file {
    "/etc/mysql/":
      ensure  => $mysql::params::ensure_confdir,
      owner   => root,
      group   => root,
      mode    => 755;
    "/etc/mysql/conf.d/":
      ensure  => directory,
      owner   => root,
      group   => root,
      mode    => 755;
    "/var/lib/mysql":
      ensure  => $mysql::params::ensure_datadir,
      target  => $mysql::params::datadir_target,
      owner   => mysql,
      group   => mysql,
      mode    => 755;
    "/etc/mysql/my.cnf":
      ensure  => present,
      owner   => root,
      group   => root,
      mode    => 644,
      source  => [ "puppet:///modules/mysql/my.cnf-$mysql::type" ],
      # we only install a config file if the package doesn't install one
      replace => false;
    "/etc/mysql/debian.cnf":
      ensure  => present,
      owner   => root,
      group   => root,
      mode    => 600;
    '/etc/mysql/conf.d/config.cnf':
      ensure  => present,
      owner   => root,
      group   => root,
      mode    => 640,
      content => template('mysql/config.cnf.erb');
  }

  if($mysql::params::notify_service) {
    File["/etc/mysql/my.cnf"] {
      notify  => Service[$mysql::params::service]
    }
    File['/etc/mysql/conf.d/config.cnf'] {
      notify  => Service[$mysql::params::service]
    }
  } else {
    File["/etc/mysql/my.cnf"] {
      notify  => Exec['mysql-send-mail-my.cnf']
    }
    File['/etc/mysql/conf.d/config.cnf'] {
      notify  => Exec['mysql-send-mail-config.cnf']
    }

    exec {'mysql-send-mail-my.cnf':
      command => "echo \"Attenzione, l'esecuzione di puppet ha modificato il file /etc/mysql/my.cnf. Schedulare un riavvio manuale del servizio\" | mail -s\"$hostname puppet modified my.cnf\" ${mysql::notification_mail}",
      refreshonly => true,
    }

    exec {'mysql-send-mail-config.cnf':
      command => "echo \"Attenzione, l'esecuzione di puppet ha modificato il file /etc/mysql/conf.d/config.cnf. Schedulare un riavvio manuale del servizio\" | mail -s\"$hostname puppet modified config.cnf\" ${mysql::notification_mail}",
      refreshonly => true,
    }

  }
}
