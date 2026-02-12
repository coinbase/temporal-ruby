require 'open3'
require 'rbconfig'
require 'temporal'

describe 'Temporal load order' do
  def run_clean_ruby(script)
    root = File.expand_path('../../../..', __dir__)
    lib_path = File.join(root, 'lib')
    gemfile = File.join(root, 'Gemfile')
    env = { 'BUNDLE_GEMFILE' => gemfile }

    Open3.capture3(
      env,
      RbConfig.ruby,
      '-rbundler/setup',
      '-I', lib_path,
      '-e', script,
      chdir: root
    )
  end

  it 'loads payload concerns without gRPC' do
    expect(Temporal::Concerns::Payloads).to be_a(Module)
  end

  it 'loads serializer constants without gRPC' do
    expect(Temporal::Connection::Serializer::Failure).to be_a(Class)
  end

  it 'loads workflow error enums at boot' do
    expect(Temporal::Workflow::Errors::WORKFLOW_ALREADY_EXISTS_SYM).not_to be_nil
  end

  it 'loads workflow history event class at boot' do
    expect(Temporal::Workflow::History::Event).to be_a(Class)
  end

  it 'does not load gRPC at require time' do
    script = <<~RUBY
      require 'temporal'
      puts(defined?(::GRPC::Core::Channel) ? 'loaded' : 'not_loaded')
    RUBY

    stdout, stderr, status = run_clean_ruby(script)
    expect(status.success?).to be(true), "stderr: #{stderr}"
    expect(stdout.strip).to eq('not_loaded')
  end

  it 'autoloads gRPC when the connection class is referenced' do
    script = <<~RUBY
      require 'temporal'
      puts(defined?(::GRPC::Core::Channel) ? 'loaded_before' : 'not_loaded_before')
      Temporal::Connection::GRPC
      puts(defined?(::GRPC::Core::Channel) ? 'loaded_after' : 'not_loaded_after')
    RUBY

    stdout, stderr, status = run_clean_ruby(script)
    expect(status.success?).to be(true), "stderr: #{stderr}"
    expect(stdout.split("\n")).to eq(%w[not_loaded_before loaded_after])
  end
end
