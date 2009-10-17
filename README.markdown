CRM Invoices
============

**This plugin is under development, and is not yet ready for use!**

The Invoices plugin for Fat Free CRM is designed to have the basic ability 
to track and ledger invoices.  You can create a payable invoice, credit note and 
demand invoice and track this to your accounts.  It isn't a full ledger, you need to 
install the ledger plugin to have this sync to international accounting standards.

Invoices are normally first Open, then Approved, then Sent.  After the invoice is
sent it can not be modified in full, only the status can be changed.  Notes and
tasks can be attached to the invoice.

Naturally after the invoice is sent the status can be tracked and you can perform
a "Late run", which allows you see what invoices are overdue and need action.  Late 
runs are peformed in the list (index) view just like how you change the options.  


Installation
============

The Invoices plugin can be installed by running:

    script/install plugin git://github.com/bkd/crm_invoices.git

Then run the following command:

    rake db:migrate:plugin NAME=crm_invoices

Then restart your web server.

----

For now we have to manually add to the settings.yml file the following

invoice_stem:
  DR_2009_

invoice_currencies: [
  ["USD",        :dollar],
  ["GBP",        :sterling],
  ["EUR",        :euro]  
]

invoice_vat: 
  "Standard"      : 17.5
  "Low"           : 6   
  "High"          : 22.5 
  "Zero"          : 0         
  
invoice_status: 
  :open          : Open         
  :approved      : Approved   
  :sent          : Sent         
  :credit        : Credit  
  :late          : Late           
  :demand        : Demand     
  :legal         : Legal         
  :paid          : Paid          

