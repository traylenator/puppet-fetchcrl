# @summary
#  Installs fetch-crl
#
# @api private
#
class fetchcrl::install (
  String[1] $pkgname             = $fetchcrl::pkgname,
  Array[String[1]] $capkgs       = $fetchcrl::capkgs,
  Stdlib::Httpurl $carepo        = $fetchcrl::carepo,
  Stdlib::Httpurl $carepo_gpgkey = $fetchcrl::carepo_gpgkey,
  Boolean $manage_carepo         = $fetchcrl::manage_carepo,
  String $capkgs_version         = $fetchcrl::capkgs_version,
  String $pkg_version            = $fetchcrl::pkg_version,
  Boolean $inet6glue             = $fetchcrl::inet6glue
) {
  assert_private()

  if $facts['os']['family'] == 'RedHat' and versioncmp($facts['os']['release']['major'],'9') >= 0 {
    $_inet6glue = false
  } else {
    $_inet6glue = $inet6glue
  }

  # The fetch-crl package.
  if $_inet6glue {
    $inet6glue_pkg = $facts['os']['family'] ? {
      'Debian' => 'libnet-inet6glue-perl',
      'RedHat' => 'perl-Net-INET6Glue',
    }

    package { $inet6glue_pkg:
      ensure => 'present',
      before => Package[$pkgname],
    }
  }

  package { $pkgname:
    ensure => $pkg_version,
  }

  if $manage_carepo {
    case $facts['os']['family'] {
      'RedHat': {
        yumrepo { 'carepo':
          descr    => 'IGTF CA Repository',
          enabled  => 1,
          baseurl  => $carepo,
          gpgcheck => 1,
          gpgkey   => $carepo_gpgkey,
        }
        $capkgs_require = Yumrepo['carepo']
      }
      'Debian': {
        apt::source { 'carepo':
          ensure        => 'present',
          comment       => 'IGTF CA Repository',
          location      => $carepo,
          key           => {
            ensure => refreshed,
            id     => '565F4528EAD3F53727B5A2E9B055005676341F1A',
            source => $carepo_gpgkey,
          },
          release       => 'egi-igtf',
          repos         => 'core',
          notify_update => true,
        }
        $capkgs_require = Apt::Source['carepo']
      }
      default: {
        fail('Yum or Apt repositories can be configured on family Debian or RedHat only')
      }
    }
  } else {
    $capkgs_require = undef
  }
  # The CA meta package.
  package { $capkgs:
    ensure  => $capkgs_version,
    require => $capkgs_require,
  }
}
