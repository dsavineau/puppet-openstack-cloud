#
# Copyright (C) 2014 eNovance SAS <licensing@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Unit tests for cloud::database::sql class
#

require 'spec_helper'

describe 'cloud::database::sql' do

    let :params do
      {
        :service_provider               => 'sysv',
        :api_eth                        => '10.0.0.1',
        :galera_master_name             => 'os-ci-test1',
        :galera_internal_ips            => ['10.0.0.1','10.0.0.2','10.0.0.3'],
        :keystone_db_host               => '10.0.0.1',
        :keystone_db_user               => 'keystone',
        :keystone_db_password           => 'secrete',
        :keystone_db_allowed_hosts      => ['10.0.0.1','10.0.0.2','10.0.0.3'],
        :cinder_db_host                 => '10.0.0.1',
        :cinder_db_user                 => 'cinder',
        :cinder_db_password             => 'secrete',
        :cinder_db_allowed_hosts        => ['10.0.0.1','10.0.0.2','10.0.0.3'],
        :glance_db_host                 => '10.0.0.1',
        :glance_db_user                 => 'glance',
        :glance_db_password             => 'secrete',
        :glance_db_allowed_hosts        => ['10.0.0.1','10.0.0.2','10.0.0.3'],
        :heat_db_host                   => '10.0.0.1',
        :heat_db_user                   => 'heat',
        :heat_db_password               => 'secrete',
        :heat_db_allowed_hosts          => ['10.0.0.1','10.0.0.2','10.0.0.3'],
        :nova_db_host                   => '10.0.0.1',
        :nova_db_user                   => 'nova',
        :nova_db_password               => 'secrete',
        :nova_db_allowed_hosts          => ['10.0.0.1','10.0.0.2','10.0.0.3'],
        :neutron_db_host                => '10.0.0.1',
        :neutron_db_user                => 'neutron',
        :neutron_db_password            => 'secrete',
        :neutron_db_allowed_hosts       => ['10.0.0.1','10.0.0.2','10.0.0.3'],
        :mysql_root_password            => 'secrete',
        :mysql_sys_maint_password       => 'sys',
        :galera_clustercheck_dbuser     => 'clustercheckuser',
        :galera_clustercheck_dbpassword => 'clustercheckpassword!',
        :galera_clustercheck_ipaddress  => '10.0.0.1'
      }
    end

    shared_examples_for 'create openstack databases' do
      before :each do
        facts.merge!( :hostname => 'os-ci-test1' )
      end

      it 'configure keystone database' do
        should contain_class('keystone::db::mysql').with(
            :dbname        => 'keystone',
            :user          => 'keystone',
            :password      => 'secrete',
            :host          => '10.0.0.1',
            :allowed_hosts => ['10.0.0.1','10.0.0.2','10.0.0.3'] )
      end

      it 'configure glance database' do
        should contain_class('glance::db::mysql').with(
            :dbname        => 'glance',
            :user          => 'glance',
            :password      => 'secrete',
            :host          => '10.0.0.1',
            :allowed_hosts => ['10.0.0.1','10.0.0.2','10.0.0.3'] )
      end

      it 'configure nova database' do
        should contain_class('nova::db::mysql').with(
            :dbname        => 'nova',
            :user          => 'nova',
            :password      => 'secrete',
            :host          => '10.0.0.1',
            :allowed_hosts => ['10.0.0.1','10.0.0.2','10.0.0.3'] )
      end

      it 'configure cinder database' do
        should contain_class('cinder::db::mysql').with(
            :dbname        => 'cinder',
            :user          => 'cinder',
            :password      => 'secrete',
            :host          => '10.0.0.1',
            :allowed_hosts => ['10.0.0.1','10.0.0.2','10.0.0.3'] )
      end

      it 'configure neutron database' do
        should contain_class('neutron::db::mysql').with(
            :dbname        => 'neutron',
            :user          => 'neutron',
            :password      => 'secrete',
            :host          => '10.0.0.1',
            :allowed_hosts => ['10.0.0.1','10.0.0.2','10.0.0.3'] )
      end

      it 'configure heat database' do
        should contain_class('heat::db::mysql').with(
            :dbname        => 'heat',
            :user          => 'heat',
            :password      => 'secrete',
            :host          => '10.0.0.1',
            :allowed_hosts => ['10.0.0.1','10.0.0.2','10.0.0.3'] )
      end
    end

  shared_examples_for 'openstack database sql with HA' do

    before do
      params.merge!(
        :ha => true
      )
    end

    let :pre_condition do
      "include xinetd"
    end

    it 'configure mysql galera server' do
      should contain_class('mysql').with(
          :server_package_name => platform_params[:server_package_name],
          :client_package_name => platform_params[:client_package_name],
          :service_name => 'mysql'
        )

      should contain_class('mysql::server').with(
          :config_hash  => { 'bind_address' => '10.0.0.1', 'root_password' => params[:mysql_root_password], 'service_name' => 'mysql' },
          :notify       => 'Service[xinetd]'
        )
    end # configure mysql galera server

    context 'configure mysqlchk http replication' do
      it { should contain_file_line('mysqlchk-in-etc-services').with(
        :line   => 'mysqlchk 9200/tcp',
        :path   => '/etc/services',
        :notify => ['Service[xinetd]', 'Exec[reload_xinetd]']
      )}

      it { should contain_file('/etc/xinetd.d/mysqlchk').with_mode('0755') }
      it { should contain_file('/usr/bin/clustercheck').with_mode('0755') }
      it { should contain_file('/usr/bin/clustercheck').with_content(/MYSQL_USERNAME="#{params[:galera_clustercheck_dbuser]}"/)}
      it { should contain_file('/usr/bin/clustercheck').with_content(/MYSQL_PASSWORD="#{params[:galera_clustercheck_dbpassword]}"/)}
      it { should contain_file('/etc/xinetd.d/mysqlchk').with_content(/bind            = #{params[:galera_clustercheck_ipaddress]}/)}

    end # configure mysqlchk http replication

    context 'create databases with HA' do
      it_behaves_like 'create openstack databases'
    end

    context 'create monitoring database' do

      before do
        facts.merge!( :hostname => 'os-ci-test1' )
      end

      it 'configure monitoring database' do
        should contain_database('monitoring').with(
          :ensure   => 'present',
          :charset  => 'utf8'
        )
        should contain_database_user("#{params[:galera_clustercheck_dbuser]}@localhost").with(
          :ensure        => 'present',
          :password_hash => '*FDC68394456829A7344C2E9D4CDFD43DCE2EFD8F',
          :provider      => 'mysql'
        )
        should contain_database_grant("#{params[:galera_clustercheck_dbuser]}@localhost/monitoring").with(
          :privileges => 'all'
        )
      end
    end # create monitoring database

  end # openstack database sql with HA

  shared_examples_for 'openstack database sql without HA' do
    before do
      params.merge!(
        :ha => false
      )
    end
    it 'configure mysql server' do
      should contain_class('mysql').with(
          :server_package_name => platform_params[:server_package_name],
          :client_package_name => platform_params[:client_package_name],
          :service_name => 'mysql'
        )

      should contain_class('mysql::server').with(
          :config_hash  => { 'bind_address' => '10.0.0.1', 'root_password' => params[:mysql_root_password], 'service_name' => 'mysql' }
        )
    end # configure mysql galera server

    context 'create databases without HA' do
      it_behaves_like 'create openstack databases'
    end

  end

  context 'on Debian platforms with HA' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :server_package_name => 'mariadb-galera-server',
        :client_package_name => 'mariadb-client',
        :wsrep_provider      => '/usr/lib/galera/libgalera_smm.so' }
    end

    it_configures 'openstack database sql with HA'
  end

  context 'on Debian platforms without HA' do
    before do
      params.merge!(
        :ha => true
      )
    end
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :server_package_name => 'mariadb-server',
        :client_package_name => 'mariadb-client' }
    end

    it_configures 'openstack database sql without HA'
  end

  context 'on RedHat platforms with HA' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :server_package_name => 'MariaDB-Galera-server',
        :client_package_name => 'MariaDB-client',
        :wsrep_provider      => '/usr/lib64/galera/libgalera_smm.so' }
    end

    it_configures 'openstack database sql with HA'
  end

  context 'on RedHat platforms without HA' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :server_package_name => 'MariaDB-server',
        :client_package_name => 'MariaDB-client' }
    end

    it_configures 'openstack database sql without HA'
  end

end
