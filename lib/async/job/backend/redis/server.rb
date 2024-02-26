# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require_relative 'delayed_queue'
require_relative 'job_store'
require_relative 'processing_queue'
require_relative 'ready_queue'

require 'securerandom'
require_relative '../../coder'

module Async
	module Job
		module Backend
			module Redis
				class Server
					def initialize(handler, client, prefix: 'async-job', coder: Coder::DEFAULT, resolution: 10)
						@handler = handler
						
						@id = SecureRandom.uuid
						@client = client
						@prefix = prefix
						@coder = coder
						@resolution = resolution
						
						@job_store = JobStore.new(@client, "#{@prefix}:jobs")
						
						@delayed_queue = DelayedQueue.new(@client, "#{@prefix}:delayed")
						@ready_queue = ReadyQueue.new(@client, "#{@prefix}:ready")
						
						@processing_queue = ProcessingQueue.new(@client, "#{@prefix}:processing", @id, @ready_queue, @job_store)
					end
					
					def start
						Console.info(self, "Starting server...")
						# Start the delayed queue, which will move jobs to the ready queue when they are ready:
						@delayed_queue.start(@ready_queue, resolution: @resolution)
						
						# Start the processing queue, which will move jobs to the ready queue when they are abandoned:
						@processing_queue.start
						
						while true
							self.dequeue
						end
					end
					
					def call(job)
						scheduled_at = Coder::Time(job[:scheduled_at])
						
						if scheduled_at
							@delayed_queue.add(@coder.dump(job), scheduled_at, @job_store)
						else
							@ready_queue.add(@coder.dump(job), @job_store)
						end
					end
					
					protected
					
					def dequeue
						id = @processing_queue.fetch
						begin
							job = @coder.load(@job_store.get(id))
							@handler.call(job)
							@processing_queue.complete(id)
						rescue => error
							@processing_queue.retry(id)
							raise
						end
					end
				end
			end
		end
	end
end
