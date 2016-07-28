class remote_agent {
  File {
    owner  => 'root',
    groupt => 'root',
    mode   => '0755',
    notify => Service['puppet-remote-agent'],
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

  service { 'remote-agent':
    ensure => running,
    enable => true,
  }
}