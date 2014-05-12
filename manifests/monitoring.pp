# = Class: mysql::monitoring
#
# Push on the host all nrpe checks usable through check_mysql_healt.
# Define mysql::monitoring::check_mysql_healt is used to push every checks
#
# == Parameters
#
# [*user_cheks*]
#   hash used to add other checks or customize default checks.
#   Default checks are:
#   * connection-time
#   * uptime
#   * threadcache-hitrate
#   * threads-created
#   * threads-running
#   * threads-cached
#   * threads-connected
#   * connects-aborted
#   * clients-aborted
#   * qcache-lowmem-prunes
#   * keycache-hitrate
#   * bufferpool-wait-free
#   * log-waits
#   * tablecache-hitrate
#   * table-lock-contention
#   * tmp-disk-tables
#   * table-fragmentation
#   * open-files
#   * slow-queries
#   * long-running-procs
#   * bufferpool-hitrate
#   * qcache-hitrate
#
# [*host*]
#   host where checks are made. Default: localhost
#
# [*port*]
#   host's port. Default: 3306
#
# [*user*]
#   database user used to make checks. Default: monitoring
#
# [*password*]
#   user's password used to make checks
#
# == Examples
#
# 1) Push only default checks with dedault threshold and without any customization. "monitoring" will be used as user, localhost:3306 will be the host, only password must be specified
#   class {'mysql::monitoring':
#     password  => 'xxxxxxxxx',
#   }
#
# 2) Customize host:port and username used to do checks. Customize threshold for check "threads-connected". To see other customizable params refer to mysql::monitoring::check_mysql_healt doc.
#   $user_cheks = {
#     'threads-connected' => { 'warning'  => '10', 'critical' => '20' }
#   }
#
#   class {'mysql::monitoring':
#     host        => '192.168.1.1',
#     port        => '3307',
#     user        => 'foo',
#     password    => 'xxxxxxxxx',
#     user_checks => $user_cheks,
#   }
# == Author
#   Felice Pizzurro <felice.pizzurro@softecspa.it>
#
class mysql::monitoring(
  $user_checks={},
  $host='localhost',
  $port='3306',
  $user='monitoring',
  $password,
  )

{
# in checks values can be:
# - {} : add the check, but do not set thresholds
# - false/nil : do not add the check
# - {warning => nil, critical => 60:} add the threshold if not nil/false

  $default_checks = {
    connection-time             =>  {},
    uptime                      =>  {},
    threadcache-hitrate         =>  {},
    threads-created             =>  {},
    threads-running             =>  {},
    threads-cached              =>  {},
    threads-connected           =>  {},
    connects-aborted            =>  {},
    clients-aborted             =>  {},
    qcache-lowmem-prunes        =>  {},
    keycache-hitrate            =>  {},
    bufferpool-wait-free        =>  {},
    log-waits                   =>  {},
    tablecache-hitrate          =>  {},
    table-lock-contention       =>  {},
    tmp-disk-tables             =>  {},
    table-fragmentation         =>  {},
    open-files                  =>  {},
    slow-queries                =>  {},
    long-running-procs          =>  {},
    bufferpool-hitrate          =>  {},
    qcache-hitrate              =>  {},
  }

  if !defined(Nrpe::Allowed_host['nrpe']) {
    fail ('You have to include nrpe class through define nrpe::allowed_host')
  }

  $checks = merge($default_checks, $user_checks)

  $mysql_hostname = $host
  $mysql_port     = $port
  $mysql_user     = $user
  $mysql_password = $password

  nrpe::check_mysql { 'mysql':
    hostname  => $mysql_hostname,
    username  => $mysql_user,
    password  => $mysql_password,
  }

  Mysql::Monitoring::Check_mysql_health {
    mysql_hostname  => $mysql_hostname,
    mysql_port      => $mysql_port,
    mysql_user      => $mysql_user,
    mysql_password  => $mysql_password
  }

  create_resources(mysql::monitoring::check_mysql_health,$checks)

  if !defined(Package['libdbd-mysql-perl']) {
    package {'libdbd-mysql-perl':
      ensure  => present
    }
  }

  nrpe::check{'mysql_all':
    checkname   => 'check_mysql_connections',
    contrib     => true,
    params      => "-K connections -H $mysql_hostname -u $mysql_user -p $mysql_password",
  }

  nrpe::check{'mysql_repl_all':
    binaryname  => 'check_mysql_all',
    checkname   => 'check_mysql_replication',
    contrib     => true,
    params      => "-K repl_all -H $mysql_hostname -u $mysql_user -p $mysql_password",
  }

  nrpe::check{'mysql_table_status':
    binaryname  => 'check_mysql_all',
    checkname   => 'check_mysql_table_status',
    contrib     => true,
    params      => "-K table_status -H $mysql_hostname -u $mysql_user -p $mysql_password",
  }
}
