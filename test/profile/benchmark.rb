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

  private

  def benchmark_clients(test_name, populate_keys = true)
    return if ENV["TEST"] and !test_name.include?(ENV["TEST"])

    @clients.keys.each do |client_name|
      next if ENV["CLIENT"] and !client_name.include?(ENV["CLIENT"])

      kid = fork do
        client = @clients[client_name].call
        begin
          if populate_keys
            client.set @k1, @m_value
            client.set @k2, @m_value
            client.set @k3, @m_value
          else
            client.delete @k1
            client.delete @k2
            client.delete @k3
          end

          GC.disable
          @benchmark.report("#{test_name}: #{client_name}") { @loops.times { yield client } }
          STDOUT.flush
        rescue Exception => e
          puts "#{test_name}: #{client_name} => #{e.inspect}" if ENV["DEBUG"]
        end
        exit
      end
      Signal.trap("INT") { Process.kill("KILL", kid); exit }
      Process.wait(kid)
    end
    puts
  end

  def run_without_recursion
    benchmark_clients("set") do |c|
      c.set @k1, @m_value
      c.set @k2, @m_value
      c.set @k3, @m_value
    end

    benchmark_clients("get") do |c|
      c.get @k1
      c.get @k2
      c.get @k3
    end

    benchmark_clients("get_multi") do |c|
      if c.respond_to?(:get_multi)
        c.get_multi @keys
      else
        c.get @keys
      end
    end

    benchmark_clients("append") do |c|
      c.append @k1, @m_value
      c.append @k2, @m_value
      c.append @k3, @m_value
    end

    benchmark_clients("prepend") do |c|
      c.prepend @k1, @m_value
      c.prepend @k2, @m_value
      c.prepend @k3, @m_value
    end

    benchmark_clients("delete") do |c|
      c.delete @k1
      c.delete @k2
      c.delete @k3
    end

    benchmark_clients("get_missing", false) do |c|
      c.get @k1 rescue nil
      c.get @k2 rescue nil
      c.get @k3 rescue nil
    end

    benchmark_clients("append_missing", false) do |c|
      c.append @k1, @m_value rescue nil
      c.append @k2, @m_value rescue nil
      c.append @k3, @m_value rescue nil
    end

    benchmark_clients("prepend_missing", false) do |c|
      c.prepend @k1, @m_value rescue nil
      c.prepend @k2, @m_value rescue nil
      c.prepend @k3, @m_value rescue nil
    end

    benchmark_clients("set_large") do |c|
      c.set @k1, @m_large_value
      c.set @k2, @m_large_value
      c.set @k3, @m_large_value
    end

    benchmark_clients("get_large") do |c|
      c.get @k1
      c.get @k2
      c.get @k3
    end

  end
end

Bench.new.run
