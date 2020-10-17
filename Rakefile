desc 'Generate ruby files from protocol buffers'
task :gen do
  Dir['proto/temporal/**/*.proto'].each do |file|
    sh "bundle exec grpc_tools_ruby_protoc -Iproto --ruby_out=lib/gen --grpc_out=lib/gen #{file}"
  end
end
