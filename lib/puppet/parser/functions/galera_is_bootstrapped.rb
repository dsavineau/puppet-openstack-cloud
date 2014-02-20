require 'timeout'
require 'socket'

Puppet::Parser::Functions::newfunction(:galera_is_bootstrapped, :type => :rvalue, :doc =>
  "Returns the status of the galera cluster (unknown, synced, timeout).") do |args|

  galera_servers = lookupvar('os_params::galera_nextserver')

  status_file="/var/lib/puppet/galera_bootstrapped"

  if File.exist?(status_file) then
    return true
  end

  #raise Puppet::ParseError, "Errors from :template function: %s" %
#
  galera_servers.each do |name, addr|
    puts "Testing if #{addr} as a running Galera server"
    begin
      timeout(3) do
        s = TCPSocket.new(addr, 9200)

        while line = s.gets do # Read lines from socket
          if /^Mariadb Cluster Node is synced/ =~ line.chomp then
            File.open(status_file, "w") {}
            return true
          end
        end
      end
    rescue
      # do nothing
    end
  end

  return false

end
