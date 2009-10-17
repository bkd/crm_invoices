namespace :crm do
  namespace :demo do
    namespace :invoices do
      desc "Load demo invoices"
      task :load => :environment do
        require 'factory_girl'
        require 'faker'
        require File.expand_path(File.dirname(__FILE__) + "/../../../../../spec/factories.rb")
        require File.expand_path(File.dirname(__FILE__) + "/../../spec/factories.rb")
        50.times do |i|
          Factory(:invoice)
        end
      end
    end
  end
end
