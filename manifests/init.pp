# Class: opencsw
#
# Manages OpenCSW and pkgutil on Solaris systems
#
class opencsw (
  $package_source = 'http://get.opencsw.org/now',
  $mirror         = 'http://mirror.opencsw.org/opencsw/stable',
  $use_gpg        = false,
  $use_md5        = false,
  $http_proxy     = undef,
  $https_proxy    = undef,
  $noncsw         = false,
  $catalog_update = 14,
) {

  validate_bool($use_gpg)
  validate_bool($use_md5)
  validate_bool($noncsw)

  # When retrieving pkgutil using a proxy, staging::file requires environment
  # variables be passed in. Similarly, the pkgutil.conf file will require
  # wgetopts be specified to use the proxy.
  if $http_proxy or $https_proxy {
    $environment = ["http_proxy=${http_proxy}", "https_proxy=${https_proxy}"]
    $wgetopts    = "-nv --execute http_proxy=${http_proxy} https_proxy=${https_proxy}"
  } else {
    $environment = undef
    $wgetopts    = '-nv'
  }

  File {
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  staging::file { 'CSWpkgutil.pkg':
    target      => '/var/sadm/pkg/CSWpkgutil.pkg',
    source      => $package_source,
    before      => Package['CSWpkgutil'],
    environment => $environment,
  }

  file { '/var/sadm/install/admin/opencsw-noask':
    ensure => file,
    source => 'puppet:///modules/opencsw/opencsw-noask',
    before => Package['CSWpkgutil'],
  }

  package { 'CSWpkgutil':
    ensure    => 'latest',
    provider  => sun,
    source    => '/var/sadm/pkg/CSWpkgutil.pkg',
    adminfile => '/var/sadm/install/admin/opencsw-noask',
  }

  # Template uses:
  #   - $mirror (can be array)
  #   - $use_gpg
  #   - $use_md5
  #   - $http_proxy
  #   - $noncsw (to use non CSW sources)
  #   - $catalog_update
  #   - $wgetopts
  file { '/etc/opt/csw/pkgutil.conf':
    ensure  => file,
    content => template("${module_name}/pkgutil.conf.erb"),
    require => Package['CSWpkgutil'],
  }

  file { '/opt/csw/etc/pkgutil.conf':
    ensure  => symlink,
    target  => '/etc/opt/csw/pkgutil.conf',
    require => Package['CSWpkgutil'],
  }

  opencsw::catalog { $mirror: }
}
