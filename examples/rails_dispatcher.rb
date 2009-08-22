ActionController::Dispatcher.class_eval do
  class << self
    def dispatch_with_spying(cgi, session_options, output)
      env = cgi.__send__(:env_table)
      puts "#{Time.now.strftime('%Y/%m/%d %H:%M:%S')} - #{env['REMOTE_ADDR']} - #{env['REQUEST_URI']}"
      dispatch_without_spying(cgi, session_options, output)
    end

    alias_method :dispatch_without_spying, :dispatch
    alias_method :dispatch, :dispatch_with_spying
  end
end