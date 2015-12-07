require "minitest/autorun"
require "timecop"

root = Pathname(__FILE__).dirname.expand_path
Dir[root.join("support", "**", "*.rb")].each { |f| require f }
