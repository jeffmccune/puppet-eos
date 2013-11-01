#
# Puppet Module  : eos
# File           : puppet/provider/eos_interface/eos.rb
#
# Copyright (c) 2013, Arista Networks
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
#   Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright notice, this
#   list of conditions and the following disclaimer in the documentation and/or
#   other materials provided with the distribution.
#
#   Neither the name of the {organization} nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
require 'rubygems'
require 'json'

Puppet::Type.type(:eos_interface).provide(:eos) do
  @doc = "Manage EOS physical interfaces"

  confine :exists=> "/etc/Eos-release"
  commands :devops => "devops"

  mk_resource_methods

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def admin=(value)
    @property_flush[:admin] = value
  end

  def description=(value)
    @property_flush[:description] = value
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    Puppet.debug("#{self.resource.type}: CREATE #{resource[:name]}")
    raise "The interface name #{resource[:name]} is invalid"
 end

  def destroy
    Puppet.debug("#{self.resource.type}: DESTROY #{resource[:name]}")
    devops('interface', 'delete', resource[:name])
  end

  def self.instances
    Puppet.debug("Searching device for resources")
    resp = JSON.parse(devops('interface', 'list'))
    resp['result'].each.collect do |key, value|
      new(:name => key,
          :ensure => :present,
          :admin => value['admin'],
          :descripton => value['description']
         )
    end
  end

  def self.prefetch(resources)
    Puppet.debug("Populating existing resources using prefetch")
    resources.keys.each do |name|
      if provider = instances.find { |instance| instance.name == name }
        Puppet.debug("Setting #{name} provider to #{provider}")
        resources[name].provider = provider
      end
    end
  end

  def flush
    Puppet.debug("#{self.resource.type}: FLUSH #{resource[:name]}")
    begin
      if @property_flush
        Puppet.debug("Flushing changed parameters")
        params= []
        (params << '--admin' << resource['admin']) if @property_flush[:admin]
        (params << '--description' << "#{resource['description']}") if @property_flush[:description]
        devops('interface', 'edit', resource[:name], params) unless params.empty?
      end
      @property_hash = resource.to_hash
    rescue Puppet::ExecutionFailure => e
      Puppet.debug("Unable to flush resource")
    end
  end
end
