require 'rake/rdoctask'
require 'rake/testtask'
require 'rake/packagetask'
require 'pp'

# get version 
require 'lib/utility/version'

# files to distribute
PKG_FILES = FileList[
  'tmud.rb', 'tclient.rb', 'dbload.rb', 'dbdump.rb', 'config.yaml',
  'LICENSE', 'CONTRIBUTORS', 'CHANGELOG', 'README', 'TML',
  'farts.grammar', 'Rakefile', 
  'db', 'db/README', 'db/testworld.yaml', 'db/dikuworld.yaml', 'db/tinyworld.yaml',
  'db/license.diku', 'db/license.tiny',
  'farts', 'farts/**/*',
  'test', 'test/**/*', 
  'logs', 'logs/README',
  'benchmark', 'benchmark/README',
  'lib/**/*',
  'cmd/**/*',
  'doc/**/*'
]

# make documentation
Rake::RDocTask.new do |rd|
  rd.rdoc_dir = 'doc'
  rd.main = 'README'
  rd.title = "TeensyMUD #{Version} Mud Server"
#  rd.template = 'kilmer'
#  rd.template = './rdoctemplate.rb'
  rd.rdoc_files.include('README', 'farts.grammar', 'TML', 'tmud.rb', 'tclient.rb',
    'dbload.rb', 'dbdump.rb',  
    'lib/*.rb', 'lib/**/*.rb', 'cmd/**/*.rb')
  rd.options << '-d' 
end

# run tests
Rake::TestTask.new do |t|
  t.libs << "vendor" << "test"  # default "lib"
  #t.pattern = 'test/test*.rb'  # default 'test/test*.rb'
  t.test_files = FileList['test/test*.rb'] - 
    ["test/test_gameobject.rb",
     "test/test_room.rb",
     "test/test_root.rb",
     "test/test_properties.rb"
    ]
  t.verbose = true
  t.options = "-c test/test_config.yaml"
end

desc "Package up a distribution"
Rake::PackageTask.new("tmud", Version) do |p|
    p.need_tar_gz = true
    p.need_zip = true
    p.package_files.include(PKG_FILES)
    p.package_files.exclude(/\.svn/)
end
  
desc "Report code statistics (KLOCs, etc) from the application"
task :stats do |t|
  require 'code_statistics'
  CodeStatistics.new(
    ["Main", ".", /^tmud.rb$|^tclient.rb$/], 
    ["Library", "lib", /.*\.rb$/], 
    ["Storage", "lib/storage", /.*\.rb$/], 
    ["Engine", "lib/engine", /.*\.rb$/], 
    ["Farts", "lib/farts", /.*\.rb$/], 
    ["Network", "lib/network", /.*\.rb$/], 
    ["Utility", "lib/utility", /.*\.rb$/], 
    ["Core", "lib/core", /.*\.rb$/], 
    ["Protocol", "lib/network/protocol", /.*\.rb$/], 
    ["Commands", "cmd/teensy", /.*\.rb$/],
    ["Benchmarks", "benchmark", /.*\.rb$/],
    ["Tests", "test", /.*\.rb$/]
  ).to_s
end

desc "Make a code release"
task :release do
  baseurl = "http://sourcery.dyndns.org/svn/teensymud"
  sh "cp pkg/tmud-#{Version}.* ../release"
  sh "cp pkg/tmud-#{Version}.* /c/ftp/pub/mud/teensymud"
  sh "svn add ../release/tmud-#{Version}.*"
  sh "svn ci .. -m 'create new packages for #{Version}'"
  sh "svn cp -m 'tagged release #{Version}' #{baseurl}/trunk #{baseurl}/release/tmud-#{Version}"
end

desc "Rebuild the parsers"
task :build_parsers do
  sh "racc -o lib/farts/farts_parser.rb lib/farts/farts_parser.y"
  sh "racc -o lib/utility/boolexp.rb lib/utility/boolexp.y"
end

task :release => [:package]
#task :clean => [:clobber_rdoc]
task :package => [:rdoc]
#task :default => [:build_parsers, :rdoc, :test]
