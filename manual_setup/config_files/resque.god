rails_env   = "production"
rails_root  = "/home/deploy/sample-app-auto/current"

# this depends on your server, we'll set it to two just for fun :D
num_workers = 2

queue = "*"

num_workers.times do |num|
  God.watch do |w|
    w.dir      = "#{rails_root}"
    w.name     = "resque-sample-app-#{num}"
    w.group    = 'resque-sample-app'
    w.interval = 30.seconds
    w.env      = {"QUEUE"=> queue, "RAILS_ENV"=>rails_env}
    w.start    = "/home/deploy/.rvm/bin/deploy_bundle exec rake -f #{rails_root}/Rakefile environment resque:work"
    w.log      = "/home/deploy/sample-app-auto/shared/log/resque-#{rails_env}.log"

    w.uid = 'deploy'
    w.gid = 'deploy'

    # restart if memory gets too high
    w.transition(:up, :restart) do |on|
      on.condition(:memory_usage) do |c|
        c.above = 350.megabytes
        c.times = 2
      end
    end

    # determine the state on startup
    w.transition(:init, { true => :up, false => :start }) do |on|
      on.condition(:process_running) do |c|
        c.running = true
      end
    end

    # determine when process has finished starting
    w.transition([:start, :restart], :up) do |on|
      on.condition(:process_running) do |c|
        c.running = true
        c.interval = 5.seconds
      end

      # failsafe
      on.condition(:tries) do |c|
        c.times = 5
        c.transition = :start
        c.interval = 5.seconds
      end
    end

    # start if process is not running
    w.transition(:up, :start) do |on|
      on.condition(:process_running) do |c|
        c.running = false
      end
    end
  end
end
