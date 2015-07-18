RSpec.configure do |config|
  config.before :suite do
    Capybara.javascript_driver = :webkit
  end
end
