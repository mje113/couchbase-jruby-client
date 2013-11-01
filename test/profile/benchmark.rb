# Useful environment variables:
#
# LOOPS (50000)
#   how many time run exercises
#
# HOST (127.0.0.1)
#   the host where cluster is running. benchmark will use default ports to
#   connect to it (11211 and 8091)
#
# STACK_DEPTH (0)
#   the depth of stack where exercises are run. the benchmark will
#   recursively go to given depth before run
#
# TEST ('')
#   use to run specific test (possible values are: set, get, get-multi,
#   append, prepend, delete, get-missing, append-missing, prepend-missing,
#   set-large, get-large)
#
# CLIENT ('')
#   use to run with specific client (possible values are: couchbase, dalli,
#   memcached, memcached:buffer)
#
# DEBUG ('')
#   show exceptions
#

require 'rubygems'
require 'bundler/setup'

$LOAD_PATH << File.join(File.dirname(__FILE__), "..", "..", "lib")
require 'couchbase'
require 'benchmark/ips'

puts `uname -a`
puts File.readlines('/proc/cpuinfo').sort.uniq.grep(/model name|cpu cores/) rescue nil
puts RUBY_DESCRIPTION

class Bench

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

    # Ensure it is JITed
    2_000.times do
      @cb.set(@k1, 'a')
      @cb.get(@k1)
    end
  end

  def run
    Benchmark.ips do |x|
      x.report('jruby set') do
        @cb.set @k1, @value
        @cb.set @k2, @value
        @cb.set @k3, @value
      end

      x.report('java set') do
        @cb.client.set(@k1, MultiJson.dump(@value)).get
        @cb.client.set(@k2, MultiJson.dump(@value)).get
        @cb.client.set(@k3, MultiJson.dump(@value)).get
      end

      x.report('jruby get') do
        @cb.get @k1
        @cb.get @k2
        @cb.get @k3
      end

      x.report('java get') do
        MultiJson.load @cb.client.get(@k1)
        MultiJson.load @cb.client.get(@k2)
        MultiJson.load @cb.client.get(@k3)
      end

      x.report('jruby delete') do
        @cb.set @k1, ''
        @cb.set @k2, ''
        @cb.set @k3, ''
        @cb.delete(@k1)
        @cb.delete(@k2)
        @cb.delete(@k3)
      end

      x.report('java delete') do
        @cb.set @k1, ''
        @cb.set @k2, ''
        @cb.set @k3, ''
        @cb.client.delete @k1
        @cb.client.delete @k2
        @cb.client.delete @k3
      end

      x.report('jruby get missing') do
        @cb.get(@k1, quiet: true)
        @cb.get(@k2, quiet: true)
        @cb.get(@k3, quiet: true)
      end

      x.report('java get missing') do
        @cb.client.get @k1
        @cb.client.get @k2
        @cb.client.get @k3
      end

      x.report('jruby async set') do
        @cb.run do
          100.times do
            @cb.set @k1, @value
            @cb.set @k2, @value
            @cb.set @k3, @value
          end
        end
      end

      x.report('java async set') do
        futures = []
        100.times do
          futures << @cb.client.set(@k1, MultiJson.dump(@value))
          futures << @cb.client.set(@k2, MultiJson.dump(@value))
          futures << @cb.client.set(@k3, MultiJson.dump(@value))
        end
        futures.each(&:get)
      end

      x.report('jruby async get') do
        @cb.run do
          100.times do
            @cb.get @k1
            @cb.get @k2
            @cb.get @k3
          end
        end
      end

      x.report('java async get') do
        futures = []
        100.times do
          futures << @cb.client.asyncGet(@k1)
          futures << @cb.client.asyncGet(@k2)
          futures << @cb.client.asyncGet(@k3)
        end
        futures.each(&:get)
      end

    end

    @cb.disconnect
  end

end

Bench.new.run
