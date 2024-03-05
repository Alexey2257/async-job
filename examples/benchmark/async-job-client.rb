#!/usr/bin/env ruby

require_relative 'config/environment'

start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

Async do
	10_000.times do
		BenchmarkJob.perform_later
	end
end

end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
puts "Started at: #{start_time}"
puts "Ended at: #{end_time}"
puts "Total time: #{end_time - start_time}"
