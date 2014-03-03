# Change this file to be a wrapper around your daemon code.

# Do your post daemonization configuration here
# At minimum you need just the first line (without the block), or a lot
# of strange things might start happening...
DaemonKit::Application.running! do |config|
	# Trap signals with blocks or procs
	# config.trap( 'INT' ) do
	#   # do something clever
	# end
	# config.trap( 'TERM', Proc.new { puts 'Going down' } )
end

# Sample loop to show process
puts "Starting CmdrHTTP on 0.0.0.0:1412"

begin
  Cmdr::CmdrRoom.new.start
rescue => e
  DaemonKit.logger.exception e
end