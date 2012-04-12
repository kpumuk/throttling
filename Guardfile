guard 'rspec', :version => 2, :cli => '--color --fail-fast --drb' do
  watch(%r{^spec/.+_spec\.rb})
  watch('lib/throttling.rb')          { 'spec'}
  watch(%r{^lib/throttling/(.+)\.rb}) { |m| "spec/#{m[1]}_spec.rb" }
end
