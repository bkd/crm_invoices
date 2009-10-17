require "fat_free_crm"

FatFreeCRM::Plugin.register(:crm_invoices, initializer) do
          name "Fat Free Invoice"
        author "Brett Dawkins"
       version "0.1"
   description "Basic invoice tracking"
  dependencies :haml, :simple_column_search
           tab :main, :text => "Invoices", :url => { :controller => "invoices" }
end

# Require the actual code after all plugin dependencies have been resoved.
require 'crm_invoices'
require "show_account_hook"
