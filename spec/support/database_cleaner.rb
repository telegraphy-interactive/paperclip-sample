# RSpec
# spec/support/database_cleaner.rb
RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
    #Rails.application.load_seed
  end

  config.around(:each) do |test|
    DatabaseCleaner.cleaning do
      test.run
    end
  end
end
