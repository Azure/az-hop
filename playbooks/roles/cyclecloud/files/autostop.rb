#!/usr/bin/env ruby

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
#

require 'json'

# Arguments
AUTOSTOP_ENABLED = `jetpack config cyclecloud.cluster.autoscale.stop_enabled`.downcase.strip == "true"
KEEPALIVE_THROTTLE = `jetpack config cyclecloud.cluster.autoscale.keep_alive_throttle 1800`.to_i
KEEPALIVE_FILE = '/opt/cycle/jetpack/run/node.keepalive'.freeze

# Short-circuit without error if not enabled
exit 0 unless AUTOSTOP_ENABLED

def log(msg)
    now = Time.now
    $stdout.write "#{now}: #{msg}\n"
end

# If a node is marked KeepAlive==true, then we don't want to autostop.
def is_keepalive?
    # we want to throtte how often we re-check that KeepAlive is true
    if File.exist?(KEEPALIVE_FILE) then
        mtime = File.mtime KEEPALIVE_FILE
    
        if (Time.new - mtime) > KEEPALIVE_THROTTLE then
            log "Deleting #{KEEPALIVE_FILE} because it has been more than #{KEEPALIVE_THROTTLE} seconds since it was created."
            log "Will be recreated the next iteration."
            File.delete KEEPALIVE_FILE
        end

        # either way, let's return true here. I want to give the autoscaler on the master a chance to terminate this
        # instance.
        return true
    end
    
    log "Checking to see if this node has KeepAlive=true"
    
    username = `jetpack config cyclecloud.config.username`.strip
    password = `jetpack config cyclecloud.config.password`.strip
    web_server = `jetpack config cyclecloud.config.web_server`.strip
    cluster_name = `jetpack config cyclecloud.cluster.name`.strip
    node_name = `jetpack config cyclecloud.node.name`.strip
    
    cluster_status = JSON.parse(`curl -k -u "#{username}:#{password}" #{web_server}/clusters/#{cluster_name}/status?nodes=true`)
    
    # Assume true so that if we did not even find ourselves we will treat this as keepalive=true
    # if something is wrong with CC and it isn't reporting this node, I don't want to keep hammering it.
    am_i_keepalive = true
    
    cluster_status["nodes"].each do |node|
       if node[:Name] == node_name then
            am_i_keepalive = node["KeepAlive"]
       end
    end
    
    # cache the response by touching this file so we can throttle
    if am_i_keepalive then
        log "This node does have KeepAlive=true. Creating #{KEEPALIVE_FILE} and will check again in #{KEEPALIVE_THROTTLE} seconds"
        touch = File.new(KEEPALIVE_FILE, 'w')
        touch.puts "This file was created because this node was marked as KeepAlive when this file was created. Will try again in #{KEEPALIVE_THROTTLE} seconds"
        touch.close
    end
        
    return am_i_keepalive
end

IDLE_TIME_AFTER_JOBS = `jetpack config cyclecloud.cluster.autoscale.idle_time_after_jobs`.to_i
IDLE_TIME_BEFORE_JOBS = `jetpack config cyclecloud.cluster.autoscale.idle_time_before_jobs`.to_i

# Checks to see if we should shutdown
idle_long_enough = false

# indicates if execute node has ever ran a job
def been_active?
  # Shell out to grep with -m 1 for lazy match, as the log files can grow quite large
  # and we only need to know if one job has ever started.
  any_job = `egrep -m 1 ';pbs_mom;Job;.+;Started' /var/spool/pbs/mom_logs/*`.strip
  any_job.length > 0
end

# indicates if there are currently running jobs
def active?
  activejobs = Dir.glob('/var/spool/pbs/mom_priv/jobs/*').count
  activejobs > 0
end

# This is our autoscale runtime configuration
runtime_config = {"idle_start_time" => nil}


AUTOSCALE_DATA = '/opt/cycle/jetpack/run/autoscale.json'.freeze

if File.exist?(AUTOSCALE_DATA)
  file = File.read(AUTOSCALE_DATA)
  runtime_config.merge!(JSON.parse(file))
end

if active?
  runtime_config["idle_start_time"] = nil
elsif runtime_config["idle_start_time"].nil?
  runtime_config["idle_start_time"] = Time.now.to_i
else
  idle_seconds = Time.now - Time.at(runtime_config["idle_start_time"].to_i)

  # Different timeouts if the node has ever run a job
  timeout = if been_active?
              IDLE_TIME_AFTER_JOBS
            else
              IDLE_TIME_BEFORE_JOBS
            end

  idle_long_enough = idle_seconds > timeout
end

# Write the config information back for next time
file = File.new(AUTOSCALE_DATA, "w")
file.puts JSON.pretty_generate(runtime_config)
file.close

# Do the shutdown if it is idle _and_ the node wasn't marked as KeepAlive.
# KeepAlive check is a bit expensive, so we will only check it if we are already idle
# and we also only check every 30 minutes by default.
if idle_long_enough && !is_keepalive?
  myhost = `hostname`
  system("bash -lc 'pbsnodes -o #{myhost}'")
  sleep(5)
  system("jetpack shutdown --idle")
end
