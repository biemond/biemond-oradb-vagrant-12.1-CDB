node 'dbcdb.example.com' {
  include oradb_os
  include oradb_cdb
 # include oradb_gg
}

Package{allow_virtual => false,}

# operating settings for Database & Middleware
class oradb_os {

  # class { 'swap_file':
  #   swapfile     => '/var/swap.1',
  #   swapfilesize => '8192000000'
  # }

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
      version                   => hiera('db_version'),
      file                      => hiera('db_file'),
      database_type             => 'EE',
      ora_inventory_dir         => hiera('oraInventory_dir'),
      oracle_base               => hiera('oracle_base_dir'),
      oracle_home               => hiera('oracle_home_dir'),
      user_base_dir             => '/home',
      user                      => hiera('oracle_os_user'),
      group                     => 'dba',
      group_install             => 'oinstall',
      group_oper                => 'oper',
      download_dir              => hiera('oracle_download_dir'),
      remote_file               => false,
      puppet_download_mnt_point => hiera('oracle_source'),
    }

    oradb::opatchupgrade{'121000_opatch_upgrade_db':
      oracle_home               => hiera('oracle_home_dir'),
      patch_file                => 'p6880880_121010_Linux-x86-64.zip',
      csi_number                => undef,
      support_id                => undef,
      opversion                 => '12.1.0.1.9',
      user                      => hiera('oracle_os_user'),
      group                     => hiera('oracle_os_group'),
      download_dir              => hiera('oracle_download_dir'),
      puppet_download_mnt_point => hiera('oracle_source'),
      require                   => Oradb::Installdb['db_linux-x64'],
    }

    oradb::opatch{'21523260_db_patch':
      ensure                    => 'present',
      oracle_product_home       => hiera('oracle_home_dir'),
      patch_id                  => '21523260',
      patch_file                => 'p21523260_121020_Linux-x86-64.zip',
      clusterware               => false,
      use_opatchauto_utility    => true,
      bundle_sub_patch_id       => '21359755',
      bundle_sub_folder         => '21359755',
      user                      => hiera('oracle_os_user'),
      group                     => 'oinstall',
      download_dir              => hiera('oracle_download_dir'),
      ocmrf                     => true,
      puppet_download_mnt_point => hiera('oracle_source'),
      require                   => Oradb::Opatchupgrade['121000_opatch_upgrade_db'],
    }

    oradb::net{ 'config net8':
      oracle_home  => hiera('oracle_home_dir'),
      version      => hiera('dbinstance_version'),
      user         => hiera('oracle_os_user'),
      group        => 'dba',
      download_dir => hiera('oracle_download_dir'),
      db_port      => '1521', #optional
      require      => Oradb::Opatch['21523260_db_patch'],
    }

    db_listener{ 'startlistener':
      ensure          => 'running',  # running|start|abort|stop
      oracle_base_dir => hiera('oracle_base_dir'),
      oracle_home_dir => hiera('oracle_home_dir'),
      os_user         => hiera('oracle_os_user'),
      require         => Oradb::Net['config net8'],
    }

    oradb::database{ 'oraDb':
      oracle_base               => hiera('oracle_base_dir'),
      oracle_home               => hiera('oracle_home_dir'),
      version                   => hiera('dbinstance_version'),
      user                      => hiera('oracle_os_user'),
      group                     => hiera('oracle_os_group'),
      download_dir              => hiera('oracle_download_dir'),
      action                    => 'create',
      db_name                   => hiera('oracle_database_name'),
      db_domain                 => hiera('oracle_database_domain_name'),
      sys_password              => hiera('oracle_database_sys_password'),
      system_password           => hiera('oracle_database_system_password'),
      template                  => 'dbtemplate_12.1',
      # template                  => 'dbtemplate_12.1_vars',
      # template_variables        => 'location01=/oracle/oradata/,location02=/oracle/oradata/',
      character_set             => 'AL32UTF8',
      nationalcharacter_set     => 'UTF8',
      sample_schema             => 'TRUE',
      memory_percentage         => '40',
      memory_total              => '1200',
      database_type             => 'MULTIPURPOSE',
      em_configuration          => 'NONE',
      data_file_destination     => hiera('oracle_database_file_dest'),
      recovery_area_destination => hiera('oracle_database_recovery_dest'),
      init_params               => {'open_cursors'        => '1000',
                                    'processes'           => '600',
                                    'job_queue_processes' => '4' },
      container_database        => true,
      require                   => Db_listener['startlistener'],
    }

    oradb::dbactions{ 'start oraDb':
      oracle_home             => hiera('oracle_home_dir'),
      user                    => hiera('oracle_os_user'),
      group                   => hiera('oracle_os_group'),
      action                  => 'start',
      db_name                 => hiera('oracle_database_name'),
      require                 => Oradb::Database['oraDb'],
    }

    oradb::autostartdatabase{ 'autostart oracle':
      oracle_home             => hiera('oracle_home_dir'),
      user                    => hiera('oracle_os_user'),
      db_name                 => hiera('oracle_database_name'),
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
      pdb_name                 => 'pdb2',
      pdb_admin_username       => 'pdb_adm',
      pdb_admin_password       => 'Welcome01',
      pdb_datafile_destination => "${oracle_database_file_dest}/${oracle_database_name}/pdb2",
      create_user_tablespace   => true,
      log_output               => true,
      require                  => Oradb::Database_pluggable['pdb1'],
    }

}

class oradb_gg {
  require oradb_cdb

    oradb::goldengate{ 'ggate12.1.2':
      version                    => '12.1.2',
      file                       => '121210_fbo_ggs_Linux_x64_shiphome.zip',
      database_type              => 'Oracle',
      database_version           => 'ORA11g',
      database_home              => hiera('oracle_home_dir'),
      oracle_base                => hiera('oracle_base_dir'),
      goldengate_home            => '/oracle/product/12.1/ggate',
      manager_port               => 16000,
      user                       => hiera('oracle_os_user'),
      group                      => 'dba',
      group_install              => 'oinstall',
      download_dir               => hiera('oracle_download_dir'),
      puppet_download_mnt_point  => hiera('oracle_source'),
    }

    file { "/oracle/product/11.2.1" :
      ensure        => directory,
      recurse       => false,
      replace       => false,
      mode          => '0775',
      owner         => hiera('oracle_os_user'),
      group         => 'dba',
      require       => Oradb::Goldengate['ggate12.1.2'],
    }

    oradb::goldengate{ 'ggate11.2.1':
      version                    => '11.2.1',
      file                       => 'ogg112101_fbo_ggs_Linux_x64_ora11g_64bit.zip',
      tar_file                   => 'fbo_ggs_Linux_x64_ora11g_64bit.tar',
      goldengate_home            => "/oracle/product/11.2.1/ggate",
      user                       => hiera('oracle_os_user'),
      group                      => 'dba',
      download_dir               => hiera('oracle_download_dir'),
      puppet_download_mnt_point  => hiera('oracle_source'),
      require                    => File["/oracle/product/11.2.1"],
    }

    oradb::goldengate{ 'ggate11.2.1_java':
      version                    => '11.2.1',
      file                       => 'V38714-01.zip',
      tar_file                   => 'ggs_Adapters_Linux_x64.tar',
      goldengate_home            => "/oracle/product/11.2.1/ggate_java",
      user                       => hiera('oracle_os_user'),
      group                      => 'dba',
      group_install              => 'oinstall',
      download_dir               => hiera('oracle_download_dir'),
      puppet_download_mnt_point  => hiera('oracle_source'),
      require                    => File["/oracle/product/11.2.1"],
    }

}