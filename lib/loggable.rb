require 'logger'

module Loggable
  def formatter
    fmtr = Logger::Formatter.new
    proc do |severity, datetime, progname, msg|
      msg = msg.dump if msg.instance_of? String
      fmtr.call(severity, datetime, progname, msg)
    end
  end

  def initlog
    logger = Logger.new(STDOUT)
    logger.formatter = formatter
    logger
  end

  def log
    @log ||= initlog # will call initlog only the first time it is called
  end
end
