#!/usr/bin/ruby

require 'fileutils'

def run_test(bld, log=nil)
	itrs = 30
	flags = '-q -s 8'
	schema = 'songdb.sql albums2.sql artists2.sql songs2.sql tags2.sql users2.sql usersongplays2.sql usersongratings2.sql'
	queries = 'query1.sql query2.sql query2-1.sql query.sql query3.sql query4.sql query5.sql query5-1.sql query6.sql query6-1.sql query7.sql query7-1.sql query8.sql query9.sql query10.sql'
	log = log.nil? ? bld : log
	
	p [bld, log]
	
	pid = Process.spawn("../../bin/sqlite/sqlite3-#{bld} #{itrs} #{flags} #{schema} #{queries} > ../../results/sqlite/#{log}.txt")
	# pid = Process.spawn("../../bin/sqlite/sqlite3-#{bld} #{itrs} #{flags} #{schema} #{queries}")
	Process.wait(pid)
end

def mv_trace(bld)
	begin
		FileUtils.mv('./max', '../../results/sqlite/trace/max-' + bld)
		FileUtils.mv('./trace', '../../results/sqlite/trace/trace-' + bld)
	rescue Exception => e
		p "welp"
	end
end

run_test('sys')
run_test('mem3')
run_test('mem5')

run_test('mem3log')
mv_trace('mem3log')
run_test('mem5log')
mv_trace('mem5log')

libs = ['hoard', 'jemalloc', 'nedmalloc']

libs.each do |l|
	ENV['LD_PRELOAD'] = '../../Replace-Libs/lib' + l + '.so'
	run_test('rmalloc', l)
end

['hoard'].each do |l|
	ENV['LD_PRELOAD'] = '../../Replace-Libs/lib' + l + '-log.so'
	run_test('rmalloc', l + '-log')
	mv_trace(l)
end
ENV['LD_PRELOAD'] = nil