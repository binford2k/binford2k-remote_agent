require 'puppet/face'
require 'pcp/client'

Puppet::Face.define(:node, '0.0.1') do
  action :run do
    summary "Run puppet on a remote node"
    arguments "<target host>"

    option "-i", "--interactive" do
      summary "Watch the full output interactively"
    end

    description <<-'EOT'
      Run Puppet on a remote node.
    EOT

    examples <<-'EOT'
      $ puppet node run testhost.example.com
      $ puppet node run -i testhost.example.com
    EOT

    when_invoked do |host, options|
      pcprun(host, 'run', options)
    end
  end

  action :report do
    summary "Get the status of the last Puppet run on a node"
    arguments "<target host>"

    description <<-'EOT'
      Get the status of the last Puppet run on a node.
    EOT

    examples <<-'EOT'
      $ puppet node status testhost.example.com
    EOT

    when_invoked do |host, options|
      pcprun(host, 'status', options)
    end
  end

  def pcprun(target, action, options)
    # Start the eventmachine reactor in its own thread
    Thread.new { EM.run }
    Thread.pass until EM.reactor_running?

    client = PCP::Client.new({:server      => "wss://#{Puppet.settings['server']}:8142/pcp",
                              :ssl_key     => Puppet.settings['hostprivkey'],
                              :ssl_cert    => Puppet.settings['hostcert'],
                              :ssl_ca_cert => Puppet.settings['cacert'],
                             })

    done = false
    response = nil
    client.on_message = proc do |message|
      data = JSON.parse(message.data)
      response = true if message[:sender] == "pcp://#{target}/remote-agent"

      case message[:message_type]
      when 'remote-agent/output'
        puts data['output']

      when 'remote-agent/results'
        done = true

        case data['output']
        when String
          puts data['output']
        else
          puts
          puts 'Last Puppet Agent Run Results:'
          puts '----------------------------------------------------------'
          data['output'].each do |key, value|
            printf " %16s: %s\n", key, value
          end
          puts
        end

      end
    end

    client.connect

    if !client.associated?
      puts "Didn't connect to broker."
      exit 1
    end

    message = PCP::Message.new({:message_type => "remote-agent/#{action}",
                                :targets      => ["pcp://#{target}/remote-agent"],
                              })

    message.data = options.to_json
    message.expires(3)
    client.send(message)

    sleep 3
    raise "#{target} did not respond" if response.nil?

    # just hang out until the agent run finishes
    until done
      sleep 1
    end
  end

end
