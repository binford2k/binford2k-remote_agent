class remote_agent {
  File {
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    notify => Service['remote-agent'],
  }

  file { '/usr/local/bin/remote-agent':
    ensure => file,
    source => 'puppet:///modules/remote_agent/remote-agent',
  }
  file { '/usr/local/bin/remote-agent-server':
    ensure => file,
    source => 'puppet:///modules/remote_agent/remote-agent-server',
  }

  file { '/usr/lib/systemd/system/remote-agent.service':
    ensure => file,
    mode   => '0644',
    source => 'puppet:///modules/remote_agent/systemd/remote-agent.service',
  }

  package { 'pcp-client':
    ensure   => present,
    provider => 'puppet_gem',
    before   => Service['remote-agent'],
  }

  service { 'remote-agent':
    ensure => running,
    enable => true,
  }
}