#!/usr/bin/ruby

require 'fileutils'
require 'pry'

class Bench
	@@mems = ['mem3', 'mem5']
	@@sizes = ['', '-128kb', '-16mb']

	@@itrs = 30
	@@flags = '-q -s 8'
	@@schema = 'songdb.sql albums2.sql artists2.sql songs2.sql tags2.sql users2.sql usersongplays2.sql usersongratings2.sql'
	@@queries = 'query1.sql query2.sql query2-1.sql query3.sql query4.sql query5.sql query5-1.sql query6.sql query6-1.sql query7.sql query7-1.sql query8.sql query9.sql query10.sql'

	@@do_perf = @@do_trace = @@do_bench = false

	def self.parse_args
		@@base_dir = ENV['BASE_DIR']
		@@results_base = '../../results/sqlite'
		ARGV.each do |a|
			@@do_bench = true if a == '-bench'
			@@do_perf = true if a == '-perf'
			@@do_trace = true if a == '-trace'
		end
	end

	def self.do_bench(itr)
		return if !@@do_bench

		run_test('sys', "sys-#{itr}", nil, itr)

		@@mems.each do |m|
			@@sizes.each { |sz| run_test("#{m}#{sz}", "#{m}#{sz}-#{itr}", nil, itr) }
		end

		['hoard', 'jemalloc', 'nedmalloc'].each do |lib|
			run_test('rmalloc', "#{lib}-#{itr}", lib, itr)
		end
	end

	def self.do_log(itr)
		return if !@@do_trace

		@@mems.each do |m|
			@@sizes.each do |sz|
				run_test("#{m}log#{sz}", "logs/#{m}#{sz}-#{itr}")
				mv_trace("#{m}#{sz}-#{itr}")
			end
		end

		['hoard'].each do |lib|
			run_test('rmalloc', "logs/#{lib}-#{itr}", "#{lib}-log")
			mv_trace("#{lib}-#{itr}")
		end
	end

private
	def self.run_test(bld, log=nil, lib=nil, perf = -1)
		c = "../../bin/sqlite/sqlite3-#{bld} #{@@itrs} #{@@flags} #{@@schema} #{@@queries}"
		cmd = ''
		cmd += "LD_PRELOAD=../../Replace-Libs/lib#{lib}.so " if !lib.nil?
		cmd_perf = cmd + "perf stat -e cycles,instructions,cache-misses,branch-misses,page-faults,cs -o #{@@results_base}/perf/#{log}.txt "
		cmd += "#{c} > #{log.nil? ? '/dev/null' : "#{@@results_base}/#{log}.txt"}"
		cmd_perf += "#{c} > /dev/null"

		puts cmd

		puts $? while((result = Kernel.system(cmd)) != true)

		if(perf >= 0 && @@do_perf)
			puts cmd_perf.gsub('stat', 'record').gsub('.txt', '.data')

			puts $? while((result = Kernel.system(cmd_perf)) != true)
			puts $? while((result = Kernel.system(cmd_perf.gsub('stat', 'record').gsub('.txt', '.data'))) != true)
		end
	end

	def self.mv_trace(bld)
		begin
			FileUtils.mv('./max', "#{@@base_dir}/results/sqlite/trace/max-#{bld}.txt")
			FileUtils.mv('./trace', "#{@@base_dir}/results/sqlite/trace/trace-#{bld}.txt")
		rescue Exception => e
			puts 'welp'
			puts e
		end
	end
end

Bench.parse_args
itrs = ARGV[0].to_i
itrs.times { |n| Bench.do_bench(n) }
itrs.times { |n| Bench.do_log(n) }