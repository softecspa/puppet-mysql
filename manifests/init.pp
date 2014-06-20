# == Class: mysql
#
# This module manages mysql installation and configuration.  It gives you the choice mysql
# server you want to use: oracle, mariadb or percona.
#
# N.B: If you don't want that puppet does mysql restart at every file's modification (for example: if you use are using drbd), you have to set
# disable_service_restart => true.
# This means that mysql root password and .my.cnf file are not managed by puppet. You have to set this manually.
#
# === Parameters:
# [*type*]
#   MySql Server to install: oracle|mariadb|percona. Default: oracle
#
# [*multi*]
#   Install MySql multi instances: true|false. Default: false
#
# [*disable_service_restart*]
#   If true, puppet manage mysql service in "no restart" mode. This mode is used when you want that puppet don't restart service when config files
#   are modified. "No restart" mode prevents puppet:
#   - to put mysql in default runlevel
#   - to modify service's status (if mysql is stopped, puppet don't start it)
#   - to notify service on config files change
#   - to set mysql password in .my.cnf file
#   Default: false
#
# [*notification_mail*]
#   Mail address used to send notification at config file modification.
#
# Other parameters are equal to mysql parameter configuration. This are available parameters with their default value:
#
#   - bind_address = '0.0.0.0',
#   - innodb_lock_wait_timeout = '120',
#   - innodb_rollback_on_timeout = 'ON',
#   - myisam_recover = 'BACKUP',
#   - open_files_limit = '32768',
#   - log_slave_updates = false,
#   - skip_external_locking = true,
#   - skip_federated = true,
#   - skip_name_resolve = true,
#   - innodb_file_per_table = true,
#   - lower_Case_table_names = 0,
#   - binlog_format = '',
#   - innodb_additional_mem_pool_size = '',
#   - innodb_buffer_pool_size = '',
#   - innodb_log_buffer_size = '',
#   - key_buffer = '',
#   - log_bin = '',
#   - log_bin_index = '',
#   - log_error = '',
#   - pid_file = '',
#   - relay_log = '',
#   - relay_log_index = '',
#   - relay_log_info_file = '',
#   - log_slow_queries = '',
#   - table_cache = '',
#   - thread_stack = '',
#   - replicate_ignore_db = '' (Array)
#
# All above parameters are written in /etc/mysql/conf.d/config.crg file. If disable_service_restart is false, mysql service will be restarted, otherwise a mail is sent
# to a address defined in notification_mail parameter.
# Parameter having a default value are every evalueted, otherwise they are writte in config file only if you specify it in class definition.
#
# === Tuning
# Please refer to mysql::config::paramfile define
#
# === Add database
# Please refer to mysql::database define documentation
#
# === Add grants
# Please refer to mysql::grant define documentation
#
# === Add monitoring
# Please refer to mysql::monitoring class
#
class mysql (
  $type='oracle',
  $version = '',
  $multi=false,
  $disable_service_restart = false,
  $notification_mail = 'notifiche@softecspa.it',
  $bind_address='0.0.0.0',
  $myisam_recover = 'BACKUP',
  $open_files_limit = '32768',

  $innodb_file_per_table = true,
  $log_slave_updates = false,
  $lower_case_table_names = 0,
  $skip_external_locking = true,
  $skip_federated = true,
  $skip_name_resolve = true,
  $skip_slave_start = false,
  $innodb_rollback_on_timeout = 'ON',
  $innodb_lock_wait_timeout = '120',

  $innodb_log_buffer_size = '',
  $innodb_buffer_pool_size = '',
  $innodb_additional_mem_pool_size = '',
  $table_cache = '',
  $table_open_cache = '',
  $key_buffer = '',
  $key_buffer_size = '',
  $thread_stack = '',
  $binlog_format = '',
  $replicate_ignore_db = '',

  $data_dir = '',
  $data_dir_target = '',
  $log_bin = '',
  $log_bin_index = '',
  $log_error = '',
  $log_slow_queries = '',
  $pid_file = '',
  $relay_log = '',
  $relay_log_index = '',
  $relay_log_info_file = '',
) {

  # validate parameters
  validate_bool($disable_service_restart)
  validate_bool($multi)
  validate_bool($skip_external_locking)
  validate_bool($skip_federated)
  validate_bool($skip_name_resolve)
  validate_bool($innodb_file_per_table)
  validate_bool($log_slave_updates)
  validate_bool($skip_slave_start)

  if $data_dir!='' {
    validate_absolute_path($data_dir)
  }
  if $data_dir_target != '' {
    validate_absolute_path($data_dir_target)
    if $data_dir == '' {
      fail('if you specify data_dir_target, data_dir must be specified. It will be a symlink to data_dir_target')
    }
  }
  if $log_bin!='' {
    validate_absolute_path($log_bin)
  }
  if $log_bin_index!='' {
    validate_absolute_path($log_bin_index)
  }
  if $log_error!='' {
    validate_absolute_path($log_error)
  }
  if $log_slow_queries!='' {
    validate_absolute_path($log_slow_queries)
  }
  if $pid_file!='' {
    validate_absolute_path($pid_file)
  }
  if $relay_log!='' {
    validate_absolute_path($relay_log)
  }
  if $relay_log_index!='' {
    validate_absolute_path($relay_log_index)
  }
  if $relay_log_info_file!='' {
    validate_absolute_path($relay_log_info_file)
  }

  if ($replicate_ignore_db != '') and (!is_array($replicate_ignore_db)) {
    fail ('parameter replicate_ignore_db must be array!')
  }

  if ( $type != 'oracle' and $type != 'mariadb' and $type != 'percona' ) {
    fail("error: value $type in variable \$type not allowed. It should be: [oracle|mariadb|percona]")
  }

  if !defined(Package['pwgen']) {
    fail('package pwgen is required')
  }

  class {"mysql::params":
    disable_service_restart => $disable_service_restart,
    version                 => $version,
  }
  include mysql::repo
  include mysql::install
  include mysql::config

  Class['mysql::params'] ->
  Class['mysql::repo'] ->
  Class['mysql::install'] ->
  Class['mysql::config']

  if($multi)
  {
    include mysql::multi
    Class['mysql::config'] -> Class['mysql::multi']
  }else
  {
    include mysql::service
    include mysql::functions
    Class['mysql::config'] -> Class['mysql::service'] -> Class['mysql::functions']
  }
}
