class mysql::params ($disable_service_restart)
{
  $packages = $mysql::type ? {
    'oracle'  =>
      $lsbdistcodename ? {
        "hardy"   => [ 'mysql-server-5.0' ],
        "lucid"   => [ 'mysql-server-5.1' ],
        "precise" => [ 'mysql-server-5.5' ],
      },
    'percona' => [ 'percona-server-server-5.5' ],
    'mariadb' => [ 'mariadb-server-5.3' ],
  }

  $packages_extra = $mysql::type ? {
    'oracle'  => [ 'maatkit', 'mytop' ],
    'percona' => [ 'maatkit', 'xtrabackup' ],
    'mariadb' => [ 'maatkit'],
  }

  $service = $mysql::type ? {
    'oracle'  => [ 'mysql' ],
    'percona' => [ 'mysql' ],
    'mariadb' => [ 'mysql' ],
  }

  $multi_password = $fqdn ? {
    default                => 'multipass',
  }

  $initscript = $mysql::multi ? {
    true   => 'puppet:///modules/mysql/init.multi',
    false =>  undef,
  }

  if($mysql::multi){
    $create_instance_script = $fqdn ? {
      default                  => "puppet:///modules/mysql/create_instance",
    }
  }

  if ($disable_service_restart) {
    $notify_service = false
    $ensure_service = undef
    $enable_service = false
    $ensure_datadir = undef
    $ensure_confdir = undef
  }
  else {
    $notify_service = true
    $ensure_service = true
    $enable_service = true
    $ensure_datadir = directory
    $ensure_confdir = directory
  }

  $disabled_db_path = '/var/disabled_db'
  $dump_option = '--quote-names --add-drop-table --add-locks --extended-insert --complete-insert --lock-all-tables --quick'
}
