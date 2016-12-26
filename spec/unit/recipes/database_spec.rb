#
# Cookbook:: odoo
# Spec:: default
#
# Copyright:: 2016, Joel Handwell
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'

describe 'odoo::database' do
  context 'When all attributes are default, on an unspecified platform' do
    let(:chef_run) do
      runner = ChefSpec::ServerRunner.new do |node|
        node.normal['postgresql']['password']['postgres'] = 'HcCCLT7dbnISt8YlDgU3'
      end.converge(described_recipe)
    end

    before do
      stub_command('ls /var/lib/postgresql/9.5/main/recovery.conf').and_return(false)
    end

    it 'install postgresql server' do
      expect(chef_run).to include_recipe('postgresql::server')
    end

    it 'creates database for odoo' do
      expect(chef_run).to create_postgresql_database('odoo').with(
        connection: {
          :host     => '127.0.0.1',
          :port     => 5432,
          :username => 'postgres',
          :password => 'HcCCLT7dbnISt8YlDgU3'
        }
      )
    end
  end
end
