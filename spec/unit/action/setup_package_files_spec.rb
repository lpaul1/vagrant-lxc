require 'unit_helper'

require 'vagrant-lxc/action/setup_package_files'

describe Vagrant::LXC::Action::SetupPackageFiles do
  let(:app)         { double(:app, call: true) }
  let(:env)         { {machine: machine, tmp_path: tmp_path, ui: double(info: true), 'package.rootfs' => rootfs_path} }
  let(:machine)     { double(Vagrant::Machine, box: box) }
  let!(:tmp_path)   { Pathname.new(Dir.mktmpdir) }
  let(:box)         { double(Vagrant::Box, directory: tmp_path.join('box')) }
  let(:rootfs_path) { tmp_path.join('rootfs-amd64.tar.gz') }

  subject { described_class.new(app, env) }

  before do
    box.directory.mkdir
    files = %w( lxc-template metadata.json lxc.conf lxc-config ).map { |f| box.directory.join(f) }
    (files + [rootfs_path]).each do |file|
      file.open('w') { |f| f.puts file.to_s }
    end

    subject.stub(recover: true) # Prevents files from being removed on specs
  end

  after do
    FileUtils.rm_rf(tmp_path.to_s)
  end

  context 'when all files exist' do
    before { subject.call(env) }

    it 'copies box lxc-template to package directory' do
      expect(env['package.directory'].join('lxc-template')).to be_file
    end

    it 'copies metadata.json to package directory' do
      expect(env['package.directory'].join('metadata.json')).to be_file
    end

    it 'copies box lxc.conf to package directory' do
      expect(env['package.directory'].join('lxc-template')).to be_file
    end

    it 'copies box lxc-config to package directory' do
      expect(env['package.directory'].join('lxc-config')).to be_file
    end

    it 'moves the compressed rootfs to package directory' do
      expect(env['package.directory'].join(rootfs_path.basename)).to be_file
      expect(env['package.rootfs']).not_to be_file
    end
  end

  context 'when lxc.conf file is not present' do
    before do
      box.directory.join('lxc.conf').delete
    end

    it 'does not blow up' do
      expect { subject.call(env) }.to_not raise_error
    end
  end

  context 'when lxc-config file is not present' do
    before do
      box.directory.join('lxc-config').delete
    end

    it 'does not blow up' do
      expect { subject.call(env) }.to_not raise_error
    end
  end
end
