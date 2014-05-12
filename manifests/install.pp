class mysql::install
{
  $rootcnf = "/root/.my.cnf"

  package {
    $mysql::params::packages:
     ensure => installed;
    $mysql::params::packages_extra:
     ensure => installed;
  }

  file {"/usr/local/bin/setmysqlpassword.sh":
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => 755,
    source  => "puppet:///modules/mysql/setmysqlpassword.sh",
  }

  if $mysql::disable_service_restart == false {
    exec { "mysql-root-password":
      command => "/usr/local/bin/setmysqlpassword.sh",
      unless  => "/usr/bin/test `grep -c password ${rootcnf}` -ge 1 -a `mysql --defaults-file=${rootcnf} -e 'show databases;' >/dev/null 2>&1; echo $?` -eq 0",
      require => [ File["/usr/local/bin/setmysqlpassword.sh"] ],
    }
  }

  file {'/usr/local/bin/mysql_secure_installation_socket':
      ensure  => present,
      owner   => root,
      group   => root,
      mode    => 755,
      source  => [ "puppet:///modules/mysql/mysql_secure_installation_socket" ];
  }
}
