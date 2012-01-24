namespace :thin do
  # Sends output to the Console on OS X. Useful for debugging.
  def logger(prefix, output)
    output.to_s.lines.each do |line|
      STDOUT.puts "#{prefix}:#{line}"
    end
  end

  # Runs and logs a command along with its output if any.
  def run(command)
    output = `#{command}`
    logger $?.to_i, command
    logger command, output
    output
  end

  # Answers the identifier of the process currently listening on the
  # given port. Runs the Unix lsof command in order to identify the
  # process. It exits with 0 if found, 1 if not found. The first line
  # of standard output contains a letter 'p' followed by the matching
  # process' PID.
  def pid_listening_on(port)
    output = run "lsof -F p -i :#{port}"
    return nil if $? != 0
    output =~ /p(\d+)/
    $1.to_i
  end

  desc "Start a new Thin background server"
  task :start do
    # The RAILS_ENV environment variable will define the Rails
    # environment: development, test or production.
    opts = []
    opts << '--daemonize'
    opts << '--debug'
    opts << '--trace'

    base_uri = URI(ENV['RAILS_BASE_URL'] || 'http://localhost:3000')
    opts << '--address'
    opts << base_uri.host
    opts << '--port'
    opts << base_uri.port
    opts << '--ssl' if base_uri.scheme == 'https'

    run "bundle exec thin #{opts.join(' ')} start"
    # The task must wait until the server starts up. Thin's --wait
    # option does not help. Instead, keep looking for a process
    # listening on the required port.
    sleep 1 until pid_listening_on base_uri.port
  end

  desc "Stop the Thin background server"
  task :stop do
    `bundle exec thin stop`
  end
end
