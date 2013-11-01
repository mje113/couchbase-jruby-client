
require 'rubygems'
require 'bundler/setup'

$LOAD_PATH << File.join(File.dirname(__FILE__), "..", "..", "lib")
require 'couchbase'
require 'jruby/profiler'

puts `uname -a`
puts File.readlines('/proc/cpuinfo').sort.uniq.grep(/model name|cpu cores/) rescue nil
puts RUBY_DESCRIPTION

class Profile

  def initialize

    puts "PID is #{Process.pid}"

    @value = { 'im' => [ 'testing', 'stuff' ] }

    puts "Raw value size is: #{@value.size} bytes"

    @keys = [
      @k1 = "Short",
      @k2 = "Sym1-2-3::45" * 8,
      @k3 = "Long" * 40,
      @k4 = "Medium" * 8,
      @k5 = "Medium2" * 8,
      @k6 = "Long3" * 40]

    @cb = Couchbase.new


  end

  def run
    profile_data = JRuby::Profiler.profile do
      2_000.times do
        @cb.set(@k1, @value)
        @cb.set(@k2, @value)
        @cb.set(@k3, @value)
      end

      2_000.times do
        @cb.get(@k1)
        @cb.get(@k2)
        @cb.get(@k3)
      end
    end

    profile_printer = JRuby::Profiler::GraphProfilePrinter.new(profile_data)
    profile_printer.printProfile(STDOUT)

    @cb.disconnect
  end

end

Profile.new.run
