require "action-controller"
require "option_parser"
require "./constants"
require "./models/*"
require "tasker"

port = Motion::DEFAULT_PORT
host = Motion::DEFAULT_HOST
process_count = Motion::DEFAULT_PROCESS_COUNT
docs = nil
docs_file = nil

OptionParser.parse(ARGV.dup) do |parser|
  parser.banner = "Motion detector"

  parser.on("-b HOST", "--bind=HOST", "Specifies the server host") { |bind_host| host = bind_host }
  parser.on("-p PORT", "--port=PORT", "Specifies the server port") { |bind_port| port = bind_port.to_i }

  parser.on("-g", "--gpio", "List the General Purpose Input Output chips available") do
    puts "\nGPIO Chips\n==================="
    Dir.glob("/dev/gpiochip*").sort!.each do |path|
      puts "* path: #{path}"

      begin
        chip = GPIO::Chip.new(Path[path])
        puts "  #{chip.name} (#{chip.label})"
        puts "  lines: #{chip.num_lines}"
      rescue error
        puts "  error: #{error.message}"
      end
    end
    puts ""
    exit 0
  end

  parser.on("-d", "--docs", "Outputs OpenAPI documentation for this service") do
    docs = ActionController::OpenAPI.generate_open_api_docs(
      title: Motion::NAME,
      version: Motion::VERSION,
      description: "Motion API"
    ).to_yaml

    parser.on("-f FILE", "--file=FILE", "Save the docs to a file") do |file|
      docs_file = file
    end
  end

  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit 0
  end
end

if docs
  File.write(docs_file.as(String), docs) if docs_file
  puts docs_file ? "OpenAPI written to: #{docs_file}" : docs
  exit 0
end

require "./config"
::Log.setup("*", :info)

puts "Launching #{Motion::NAME} v#{Motion::VERSION}"
server = ActionController::Server.new(port, host)
server.cluster(process_count, "-w", "--workers") if process_count != 1

state = Motion::State.instance
state.start

# Shutdown gracefully
Process.on_terminate do
  puts " > terminating gracefully"
  spawn do
    state.shutdown
    server.close
  end
end

Motion.register_severity_switch_signals

# Start the server
server.run do
  puts "Listening on #{server.print_addresses}"
end

puts "#{Motion::NAME} leaps through the veldt\n"
