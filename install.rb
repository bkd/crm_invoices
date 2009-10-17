# Install hook code here

puts <<-EOF
The Invoices plugin for Fat Free CRM is designed to have the basic ability 
to track and ledger invoices.  You can create a payable invoice, credit note and 
demand invoice and track this to your accounts.  It isn't a full ledger, you need to 
install the ledger plugin to have this sync to international accounting standards.

Once the plugin is installed run the following command:

  rake db:migrate:plugin NAME=crm_invoices

EOF