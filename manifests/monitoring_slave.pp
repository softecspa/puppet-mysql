# = Class: mysql::monitoring_slave
#
# Push on the host all nrpe checks referred to a slave mysql slave instance usable through check_mysql_healt.
# Define mysql::monitoring::check_mysql_healt is used to push every checks
#
# == Parameters
#
# [*user_cheks*]
#   hash used to add other checks or customize default checks.
#   Default checks are:
#   * slave-io-running
#   * slave-sql-running
#   * slave-lag
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
#   user's password used to make checks. Mandatory
#
# == Examples
#
# 1) Push only default checks with dedault threshold and without any customization. "monitoring" will be used as user, localhost:3306 will be the host, only password must be specified
#   class {'mysql::monitoring':
#     password  => 'xxxxxxxxx',
#   }
#
# 2) Customize host:port and username used to do checks. Customize threshold for check "slave-lag". To see other customizable params refer to mysql::monitoring::check_mysql_healt doc.
#   $user_cheks = {
#     'slave-lag' => { 'warning'  => '1000', 'critical' => '2000' }
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
class mysql::monitoring_slave(
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
    slave-io-running  =>  {},
    slave-sql-running =>  {},
    slave-lag         =>  {},
  }

  if !defined(Nrpe::Allowed_host['nrpe']) {
    fail ('You have to include nrpe class through define nrpe::allowed_host')
  }

  $checks = merge($default_checks, $user_checks)

  Mysql::Monitoring::Check_mysql_health {
    mysql_hostname  => $host,
    mysql_port      => $port,
    mysql_user      => $user,
    mysql_password  => $password
  }

  create_resources(mysql::monitoring::check_mysql_health,$checks)
}
