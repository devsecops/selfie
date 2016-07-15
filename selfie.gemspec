Gem::Specification.new do |s|
  s.name    = 'selfie'
  s.version = '1.0.0'
  s.date    = Time.now.utc.strftime('%Y-%m-%d')
  s.summary = 'Let me take a selfie, a snapshot of an AWS instance'
  s.bindir  = 'bin'
  s.executables << 'selfie'
  s.description = s.summary
  s.authors = ['Javier Godinez']
  s.email   = 'godinezj@gmail.com'
  s.files   = `git ls-files -z`.split("\x0")
  s.require_paths = %w(lib)
  s.homepage = 'https://github.com/devsecops/selfie'
  s.license = 'Apache License 2.0'
  s.add_runtime_dependency 'aws-sdk', '~> 2.1'
end
