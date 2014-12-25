node 'dbcdb.example.com' {
  include oradb_os
  include oradb_cdb
}

Package{allow_virtual => false,}

# operating settings for Database & Middleware
class oradb_os {

  class { 'swap_file':
    swapfile     => '/var/swap.1',
    swapfilesize => '8192000000'
  }

  # set the tmpfs
  mount { '/dev/shm':
    ensure      => present,
    atboot      => true,
    device      => 'tmpfs',
    fstype      => 'tmpfs',
    options     => 'size=2000m',
  }

  $host_instances = hiera('hosts', {})
  create_resources('host',$host_instances)

  service { iptables:
    enable    => false,
    ensure    => false,
    hasstatus => true,
  }

  $all_groups = ['oinstall','dba' ,'oper']

  group { $all_groups :
    ensure      => present,
  }

  user { 'oracle' :
    ensure      => present,
    uid         => 500,
    gid         => 'oinstall',
    groups      => ['oinstall','dba','oper'],
    shell       => '/bin/bash',
    password    => '$1$DSJ51vh6$4XzzwyIOk6Bi/54kglGk3.',
    home        => '/home/oracle',
    comment     => 'This user oracle was created by Puppet',
    require     => Group[$all_groups],
    managehome  => true,
  }

  $install = ['binutils.x86_64', 'compat-libstdc++-33.x86_64', 'glibc.x86_64',
              'ksh.x86_64','libaio.x86_64',
              'libgcc.x86_64', 'libstdc++.x86_64', 'make.x86_64',
              'compat-libcap1.x86_64', 'gcc.x86_64',
              'gcc-c++.x86_64','glibc-devel.x86_64','libaio-devel.x86_64',
              'libstdc++-devel.x86_64',
              'sysstat.x86_64','unixODBC-devel','glibc.i686','libXext.x86_64',
              'libXtst.x86_64','xorg-x11-xauth.x86_64',
              'elfutils-libelf-devel','kernel-debug']


  package { $install:
    ensure  => present,
  }

  class { 'limits':
    config => {
                '*'       => { 'nofile'  => { soft => '2048'   , hard => '8192',   },},
                'oracle'  => { 'nofile'  => { soft => '65536'  , hard => '65536',  },
                                'nproc'  => { soft => '2048'   , hard => '16384',  },
                                'stack'  => { soft => '10240'  ,},},
                },
    use_hiera => false,
  }

  sysctl { 'kernel.msgmnb':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.msgmax':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.shmmax':                 ensure => 'present', permanent => 'yes', value => '2588483584',}
  sysctl { 'kernel.shmall':                 ensure => 'present', permanent => 'yes', value => '2097152',}
  sysctl { 'fs.file-max':                   ensure => 'present', permanent => 'yes', value => '6815744',}
  sysctl { 'net.ipv4.tcp_keepalive_time':   ensure => 'present', permanent => 'yes', value => '1800',}
  sysctl { 'net.ipv4.tcp_keepalive_intvl':  ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'net.ipv4.tcp_keepalive_probes': ensure => 'present', permanent => 'yes', value => '5',}
  sysctl { 'net.ipv4.tcp_fin_timeout':      ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'kernel.shmmni':                 ensure => 'present', permanent => 'yes', value => '4096', }
  sysctl { 'fs.aio-max-nr':                 ensure => 'present', permanent => 'yes', value => '1048576',}
  sysctl { 'kernel.sem':                    ensure => 'present', permanent => 'yes', value => '250 32000 100 128',}
  sysctl { 'net.ipv4.ip_local_port_range':  ensure => 'present', permanent => 'yes', value => '9000 65500',}
  sysctl { 'net.core.rmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.rmem_max':             ensure => 'present', permanent => 'yes', value => '4194304', }
  sysctl { 'net.core.wmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.wmem_max':             ensure => 'present', permanent => 'yes', value => '1048576',}

}

class oradb_cdb {
  require oradb_os

    oradb::installdb{ 'db_linux-x64':
      version                => hiera('db_version'),
      file                   => hiera('db_file'),
      databaseType           => 'EE',
      oraInventoryDir        => hiera('oraInventory_dir'),
      oracleBase             => hiera('oracle_base_dir'),
      oracleHome             => hiera('oracle_home_dir'),
      userBaseDir            => '/home',
      createUser             => false,
      user                   => hiera('oracle_os_user'),
      group                  => 'dba',
      group_install          => 'oinstall',
      group_oper             => 'oper',
      downloadDir            => hiera('oracle_download_dir'),
      remoteFile             => false,
      puppetDownloadMntPoint => hiera('oracle_source'),
    }

    oradb::net{ 'config net8':
      oracleHome   => hiera('oracle_home_dir'),
      version      => hiera('dbinstance_version'),
      user         => hiera('oracle_os_user'),
      group        => 'dba',
      downloadDir  => hiera('oracle_download_dir'),
      dbPort       => '1521', #optional
      require      => Oradb::Installdb['db_linux-x64'],
    }

    oradb::listener{'start listener':
      oracleBase   => hiera('oracle_base_dir'),
      oracleHome   => hiera('oracle_home_dir'),
      user         => hiera('oracle_os_user'),
      group        => 'dba',
      action       => 'start',
      require      => Oradb::Net['config net8'],
    }

    oradb::database{ 'oraDb':
      oracleBase              => hiera('oracle_base_dir'),
      oracleHome              => hiera('oracle_home_dir'),
      version                 => hiera('dbinstance_version'),
      user                    => hiera('oracle_os_user'),
      group                   => hiera('oracle_os_group'),
      downloadDir             => hiera('oracle_download_dir'),
      action                  => 'create',
      dbName                  => hiera('oracle_database_name'),
      dbDomain                => hiera('oracle_database_domain_name'),
      sysPassword             => hiera('oracle_database_sys_password'),
      systemPassword          => hiera('oracle_database_system_password'),
      characterSet            => 'AL32UTF8',
      nationalCharacterSet    => 'UTF8',
      sampleSchema            => 'FALSE',
      memoryPercentage        => '40',
      memoryTotal             => '800',
      databaseType            => 'MULTIPURPOSE',
      emConfiguration         => 'NONE',
      dataFileDestination     => hiera('oracle_database_file_dest'),
      recoveryAreaDestination => hiera('oracle_database_recovery_dest'),
      initParams              => {'open_cursors'        => '1000',
                                  'processes'           => '600',
                                  'job_queue_processes' => '4' },
      containerDatabase       => true,
      require                 => Oradb::Listener['start listener'],
    }

    oradb::dbactions{ 'start oraDb':
      oracleHome              => hiera('oracle_home_dir'),
      user                    => hiera('oracle_os_user'),
      group                   => hiera('oracle_os_group'),
      action                  => 'start',
      dbName                  => hiera('oracle_database_name'),
      require                 => Oradb::Database['oraDb'],
    }

    oradb::autostartdatabase{ 'autostart oracle':
      oracleHome              => hiera('oracle_home_dir'),
      user                    => hiera('oracle_os_user'),
      dbName                  => hiera('oracle_database_name'),
      require                 => Oradb::Dbactions['start oraDb'],
    }

    $oracle_database_file_dest = hiera('oracle_database_file_dest')
    $oracle_database_name = hiera('oracle_database_name')

    oradb::database_pluggable{'pdb1':
      ensure                   => 'present',
      version                  => '12.1',
      oracle_home_dir          => hiera('oracle_home_dir'),
      user                     => hiera('oracle_os_user'),
      group                    => 'dba',
      source_db                => hiera('oracle_database_name'),
      pdb_name                 => 'pdb1',
      pdb_admin_username       => 'pdb_adm',
      pdb_admin_password       => 'Welcome01',
      pdb_datafile_destination => "${oracle_database_file_dest}/${oracle_database_name}/pdb1",
      create_user_tablespace   => true,
      log_output               => true,
      require                  => Oradb::Autostartdatabase['autostart oracle'],
    }

    oradb::database_pluggable{'pdb2':
      ensure                   => 'present',
      version                  => '12.1',
      oracle_home_dir          => hiera('oracle_home_dir'),
      user                     => hiera('oracle_os_user'),
      group                    => 'dba',
      source_db                => hiera('oracle_database_name'),
      pdb_name                 => 'pdb1',
      pdb_admin_username       => 'pdb_adm',
      pdb_admin_password       => 'Welcome01',
      pdb_datafile_destination => "${oracle_database_file_dest}/${oracle_database_name}/pdb2",
      create_user_tablespace   => true,
      log_output               => true,
      require                  => Oradb::Satabase_pluggable['pdb1'],
    }


    # oradb::database_pluggable{'pdb1':
    #   ensure                   => 'absent',
    #   version                  => '12.1',
    #   oracle_home_dir          => hiera('oracle_home_dir'),
    #   user                     => hiera('oracle_os_user'),
    #   group                    => 'dba',
    #   source_db                => hiera('oracle_database_name'),
    #   pdb_name                 => 'pdb1',
    #   pdb_datafile_destination => "${oracle_database_file_dest}/${oracle_database_name}/pdb1",
    #   log_output               => true,
    #   require                  => Oradb::Autostartdatabase['autostart oracle'],
    # }

}

