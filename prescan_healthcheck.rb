#!/usr/bin/env ruby

require 'rubygems'
require 'nexpose'
require 'io/console'
#require 'pp'
require 'Time'


#vars
host = 'FQDN OR IP HERE'
port = '3780'
user = 'PUT YOUR USERNAME HERE'
pass = 'PASSWORD HERE'

#Create connector
puts "Nexpose Pre-Scan Health Check Script: v1.0 20140310"
puts "\nConnecting to #{host} as #{user}..."
nsc = Nexpose::Connection.new(host, user, pass, port)

begin
		#auth
		nsc.login
		#clean logout
		at_exit { nsc.logout }
		
rescue ::Nexpose::APIError => err
		$stderr.puts("Connection failed: #{e.reason}")
		exit(1)
end

#Check system info
sysinfo = nsc.system_information
#pp sysinfo

#One blink for yes, two blinks for no!
class Beep
	#The use of "self" init a class method rather than instance method
	def self.pass
		print "\a"
	end
	def self.fail
		print "\a \a"
	end
end

begin
#Check for the last update
NSCLastUpdate = sysinfo["last-update-date"]
CTime = Time.now.to_i
#Check to see if the update was within last 7 days
	if (CTime + 604800) < NSCLastUpdate.to_i
		puts "Last Update: OK"
	elsif (CTime + 604800) >= NSCLastUpdate.to_i
		puts "Last Update: Not Updated within 7 days"
		puts Time.at(CTime)
		Beep.fail
		puts "Starting update. Please wait."
		NSCUpdate = nsc.console_command("updatenow")
		puts NSCUpdate
		puts "Pushing update to scan engines. Please wait."
		EngineUpdate = nsc.console_command("update engines")
	end

rescue StandardError => UpdateError
	print UpdateError
	
end

begin
#Check memory utilization
NSCFreeMem = sysinfo["ram-free"]
NSCTotalMem = sysinfo["ram-total"]
NSCMemUse = (NSCFreeMem.to_i / NSCTotalMem.to_i)
#Check to see if we are at 75% or greater usage
	if NSCMemUse < (0.75)
		puts "Memory Usage: OK"
	elsif NSCMemUse >= (0.75)
		puts "Memory Usage: Above 75%"
		puts "Utilization:" + NSCMemUse.to_s
		Beep.fail
		puts "Attempting to free up Java resources. Please wait."
		GarbageCollect = nsc.console_command("garbagecollect")
		puts GarbageCollect
	end

rescue StandardError => MemError
	print MemError
	
end

begin
#Check up time
NSCUpTime = sysinfo["up-time"]
NSCUpTimeThreshold = 600
#Check to see if up time is greater than 5 minutes
	if NSCUpTime.to_i >= NSCUpTimeThreshold
		puts "Uptime: OK"
	elsif NSCUpTime.to_i <= NSCUpTimeThreshold
		puts "Uptime: Recent service restart. Potential Issue."
		Beep.fail
	end

rescue StandardError => UptimeError
	print UptimeError

end
