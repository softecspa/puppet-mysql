class mysql::service
{
  service {
    $mysql::params::service:
      enable     => $mysql::params::enable_service,
      ensure     => $mysql::params::ensure_service,
      hasrestart => true,
      hasstatus  => true,
  }

}
