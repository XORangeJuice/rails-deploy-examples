# not config, just a variable
pid_file_path = '/home/deploy/sample-app/tmp/unicorn.pid'

# location of PID file
pid pid_file_path

# listening on a Unix socket gives us a performance bump
listen "/tmp/sample-app.sock"

# where does our project currently live?
working_directory '/home/deploy/sample-app/'

# how long can a worker run (in seconds) before being killed
timeout 60

# preload the app _before_ forking occurs
preload_app true

# how many worker processes to run?
# a general rule of thumb is CPU count + 1, but there are lots of caveats that
# you need to consider, it's worth experimenting with
worker_processes 2

# the crux of zero-downtime restarts, we'll get into this later
before_fork do |server, worker|
  old_pid = "#{pid_file_path}.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # uh, sweet, someone else killed unicorn for us
    end
  end
end

# what should we do after forking?
after_fork do |server, worker|
  # reconnect to our databases. :D
  ActiveRecord::Base.establish_connection
end