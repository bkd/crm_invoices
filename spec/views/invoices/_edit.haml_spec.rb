require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/invoices/edit.html.erb" do
  include InvoicesHelper
  
  before(:each) do
    login_and_assign
    assigns[:invoice] = @invoice = Factory(:invoice)
    assigns[:users] = [ @current_user ]
    assigns[:status] = %w(open approved)
    assigns[:account] = @account= Factory(:invoice)
  end

  it "should render [edit invoice] form" do
    template.should_receive(:render).with(hash_including(:partial => "invoices/top_section"))
    template.should_receive(:render).with(hash_including(:partial => "invoices/status"))
    template.should_receive(:render).with(hash_including(:partial => "invoices/web"))
    template.should_receive(:render).with(hash_including(:partial => "invoices/permissions"))

    render "/invoices/_edit.html.haml"
    response.should have_tag("form[class=edit_invoice]") do
      with_tag "input[type=hidden][id=invoice_user_id][value=#{@invoice.user_id}]"
    end
  end

end


