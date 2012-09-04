
# Requires $platformdomainextension and $nodename to be set

class sipx {


  package {
    'sipxecs':
      ensure => present;
  }



  file {
    '/etc/sipxpbx/':
      ensure => directory;
    '/etc/sipxpbx/ssl/':
      ensure => directory;
    '/var/sipxdata/':
      owner   => 'sipxchange',
      group   => 'sipxchange',
      recurse => true;
    '/var/sipxdata/certdb/':
      owner  => sipxchange,
      group  => sipxchange;
    '/etc/sipxpbx/domain-config':
      content => template('sipx/domain-config.erb'),
      replace => false;
  }


  service {'postgresql':
    enable  => true,
    require => Package['sipxecs'];
  'vsftpd':
    ensure =>  stopped;
  'iptables':
    ensure => stopped,
    enable => false;
  }
}
class sipx::runslave inherits sipx {
  service {
    'sipxecs':
      ensure    => $ensure_service,
      enable    => true,
      hasstatus => true,
      require   => [Package['sipxecs'],File['/etc/sipxpbx/sipxconfig-netif','/etc/sipxpbx/domain-config','/etc/sipxpbx/ssl/ssl.crt','/etc/sipxpbx/ssl/ssl.key']];

  }
}


class  sipx::runmaster inherits sipx {

  service { 'sipxecs':
    ensure    => 'running',
    enable    => true,
    hasstatus => true,
    require   => [File['/etc/sipxpbx/sipxconfig-netif','/etc/sipxpbx/domain-config','/etc/sipxpbx/ssl/ssl.crt','/etc/sipxpbx/ssl/ssl.key','/var/sipxdata/process-state/ConfigServer']];
  }


}


define sipx::netconfig ( $ipaddress, $netmask)
{
  file {
    '/etc/sipxpbx/sipxconfig-netif':
      content => template('sipx/sipxconfig-netif.erb'),
      owner   => 'sipxchange',
      group   => 'sipxchange';
  }
}


define sipx::configserver ()
{



  file { '/var/sipxdata/process-state/ConfigServer':
    source  => 'puppet:///modules/sipx/Enabled',
    owner   => sipxchange, group => sipxchange,
    require => Package['sipxecs'],
    replace => false;

  }

}


define sipx::gensslreq($platformdomainextension)
{

  # Running genssl on puppet master first ...
  # Then transfer files to remote nodes


  file {

    '/usr/bin/ssl-cert/':
      ensure => directory;

    '/usr/bin/ssl-cert/ca_rehash':
      source => 'puppet:///modules/sipx/ssl-cert/ca_rehash',
      mode   => '0755';

    '/usr/bin/ssl-cert/check-cert.sh':
      source => 'puppet:///modules/sipx/ssl-cert/check-cert.sh',
      mode   => '0755';

    '/usr/bin/ssl-cert/gen-ssl-keys.sh':
      source => 'puppet:///modules/sipx/ssl-cert/gen-ssl-keys.sh',
      mode   => '0755';

    '/usr/bin/ssl-cert/install-cert.sh':
      source => 'puppet:///modules/sipx/ssl-cert/install-cert.sh',
      mode   => '0755';

    '/usr/bin/ssl-cert/upgrade-cert.sh':
      ensure => present,
      source => 'puppet:///modules/sipx/ssl-cert/upgrade-cert.sh',
      mode   => '0755';


    '/usr/local/bin/genssl.sh':
      source => 'puppet:///modules/sipx/genssl.sh',
      mode   => '0755';
    '/etc/puppet/':
      ensure => directory;
    '/etc/puppet/modules/':
      ensure => directory;
    '/etc/puppet/modules/sipx/':
      ensure => directory;
    '/etc/puppet/modules/sipx/files/':
      ensure => directory;
    '/etc/puppet/modules/sipx/files/certdb/':
      ensure => directory;
    '/etc/puppet/modules/sipx/files/certdb/SSL_DEFAULTS':
      content => template('sipx/SSL_DEFAULTS.erb');

  }
}
define sipx::genssl($hostname)
{
  exec { '/usr/local/bin/genssl.sh $hostname':
    require => File['/etc/puppet/modules/sipx/files/certdb/SSL_DEFAULTS'];

  }

}

define sipx::supervisor($sipx_supervisor) {
  file {
    '/etc/sipxpbx/sipxsupervisor-config':
      content => template('sipx/sipxsupervisor-config.erb'),
      owner   => 'sipxchange',
      group   => 'sipxchange',
      replace => false;

  }
}


define sipx::staticcertdbca(){
  file {
    #     '/var/sipxdata/certdb/':
    #              owner => sipxchange, group => sipxchange,
    #              ensure => directory;
    '/var/sipxdata/certdb/SSL_DEFAULTS':
      content => template('sipx/SSL_DEFAULTS.erb'),
      owner   => 'sipxchange',
      group   => 'sipxchange';
    '/var/sipxdata/certdb/ca.$platformdomainextension.crt':
      source => 'puppet:///modules/sipx/certdb/ca.$platformdomainextension.crt',
      owner  => 'sipxchange',
      group  => 'sipxchange';
    '/var/sipxdata/certdb/ca.$platformdomainextension.csr':
      source => 'puppet:///modules/sipx/certdb/ca.$platformdomainextension.csr',
      owner  => 'sipxchange',
      group  => 'sipxchange';
    '/var/sipxdata/certdb/ca.$platformdomainextension.key':
      source => 'puppet:///modules/sipx/certdb/ca.$platformdomainextension.key',
      group  => 'sipxchange';
    '/var/sipxdata/certdb/ca.$platformdomainextension.ser':
      source => 'puppet:///modules/sipx/certdb/ca.$platformdomainextension.ser',
      owner  => 'sipxchange',
      group  => 'sipxchange';
    '/var/sipxdata/certdb/rnd_seed':
      source => 'puppet:///modules/sipx/certdb/rnd_seed',
      owner  => 'sipxchange',
      group  => 'sipxchange';
  }


}



define sipx::register($clientname,$password){



  file {
    '/usr/local/bin/register-sipx.sh':
      mode    => '0755',
      owner   => sipxchange,
      group   => sipxchange,
      content => template('sipx/register-sipx.sh.erb');
    }

    exec { '/usr/local/bin/register-sipx.sh':
    command => '/usr/local/bin/register-sipx.sh',
    unless  => '/usr/bin/test -e /tmp/post-install/variables.txt',
    }


}



define sipx::staticcertdbnodes($clientname){

  file {

    "/var/sipxdata/certdb/${clientname}.${platformdomainextension}.crt":
      ensure => present,
      source => "puppet:///modules/sipx/certdb/${clientname}.${platformdomainextension}.crt",
      owner  => 'sipxchange',
      group  => 'sipxchange',
      mode   => '0600';
    "/var/sipxdata/certdb/${clientname}.${platformdomainextension}.csr":
      ensure => present,
      source => "puppet:///modules/sipx/certdb/${clientname}.${platformdomainextension}.csr",
      owner  => 'sipxchange',
      group  => 'sipxchange',
      mode   => '0600';
    "/var/sipxdata/certdb/${clientname}.${platformdomainextension}.key":
      ensure => present,
      source => "puppet:///modules/sipx/certdb/${clientname}.${platformdomainextension}.key",
      owner  => 'sipxchange',
      group  => 'sipxchange',
      mode   => '0600';
    "/var/sipxdata/certdb/${clientname}.${platformdomainextension}.p12":
      ensure => present,
      source => "puppet:///modules/sipx/certdb/${clientname}.${platformdomainextension}.p12",
      owner  => 'sipxchange',
      group  => 'sipxchange',
      mode   => '0600';
    "/var/sipxdata/certdb/${clientname}.${platformdomainextension}_crt.cfg":
      ensure => present,
      source => "puppet:///modules/sipx/certdb/${clientname}.${platformdomainextension}_crt.cfg",
      owner  => 'sipxchange',
      group  => 'sipxchange',
      mode   => '0600';
  }

}
define sipx::staticssl()
{
  # We'll be transferring static ssl certificates here.
  # First step is to have them generated on an initial sipx, then copied back
  # Next step is to generated om the puppetmaster
  # We also need to fix the ttl of the certificates

  # Docs from http://wiki.sipfoundry.org/pages/viewpage.action?pageId=9928981


  file {
    '/etc/sipxpbx/ssl/ssl.crt':
      ensure => present,
      source => 'puppet:///modules/sipx/certdb/$hostname.$platformdomainextension.crt',
      owner  => 'sipxchange',
      group  => 'sipxchange',
      mode   => '0600';
    '/etc/sipxpbx/ssl/ssl.key':
      ensure => present,
      source => 'puppet:///modules/sipx/certdb/$hostname.$platformdomainextension.key',
      owner  => 'sipxchange',
      group  => 'sipxchange',
      mode   => '0600';
    '/etc/sipxpbx/ssl/ssl-web.crt':
      ensure => present,
      source => 'puppet:///modules/sipx/certdb/$hostname.$platformdomainextension.crt',
      owner  => 'sipxchange',
      mode   => '0600',
      group  => 'sipxchange';
    '/etc/sipxpbx/ssl/ssl-web.key':
      source => 'puppet:///modules/sipx/certdb/$hostname.$platformdomainextension.key',
      mode   => '0600',
      owner  => 'sipxchange',
      group  => 'sipxchange';
    '/etc/sipxpbx/ssl/authorities':
      ensure => directory,
      mode   => '0600',
      owner  => 'sipxchange',
      group  => 'sipxchange';
    '/etc/sipxpbx/ssl/authorities/ca.$platformdomainextension.crt':
      mode   => '0600',
      owner  => 'sipxchange',
      group  => 'sipxchange',
      source => 'puppet:///modules/sipx/certdb/ca.$platformdomainextension.crt';


    }



    # Also need to transfer the CA stuff to the SIPX-A, or maybe even to the B


    # And figure out how / why the 2nd node still isn't registered on the A server ..   I should be able to run the initial-config from a browser including  the shared password to solve this

    #   Still not sure where the authorities.jks comes from  in the generated B setup it isn't present
    #'/etc/sipxpbx/ssl/authorities.jks':




    #'/etc/sipxpbx/ssl/ssl.keystore':   Generated on server
    #'/etc/sipxpbx/ssl/ssl.p12':        Not used
    #'/etc/sipxpbx/ssl/ssl-web.p12':    Not used



}
