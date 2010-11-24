require 'puppet/provider/parsedfile'

hosts = nil
case Facter.value(:operatingsystem)
when "Solaris"; hosts = "/etc/inet/hosts"
else
  hosts = "/etc/hosts"
end


Puppet::Type.type(:host).provide(:parsed,:parent => Puppet::Provider::ParsedFile,
  :default_target => hosts,:filetype => :flat) do
  confine :exists => hosts

  text_line :comment, :match => /^#/
  text_line :blank, :match => /^\s*$/

  record_line :parsed, :fields => %w{ip name host_aliases comment},
    :optional => %w{host_aliases comment},
    :match    => /^(\S+)\s+(\S+)\s*(.*?)?(?:\s*#\s*(.*))?$/,
    :post_parse => proc { |hash|
      # An absent comment should match "comment => ''"
      hash[:comment] = '' if hash[:comment].nil? or hash[:comment] == :absent
      unless hash[:host_aliases].nil? or hash[:host_aliases] == :absent
        hash[:host_aliases] = hash[:host_aliases].split(/\s+/)
      else
        hash[:host_aliases] = []
      end
    },
    :to_line  => proc { |hash|
      [:ip, :name].each do |n|
        raise ArgumentError, "#{n} is a required attribute for hosts" unless hash[n] and hash[n] != :absent
      end
      str = "#{hash[:ip]}\t#{hash[:name]}"
      if hash.include? :host_aliases and !hash[:host_aliases].empty?
        str += "\t#{hash[:host_aliases].join("\t")}"
      end
      if hash.include? :comment and !hash[:comment].empty?
        str += "\t# #{hash[:comment]}"
      end
      str
    }
end
