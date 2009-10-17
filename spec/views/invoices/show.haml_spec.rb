require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/invoices/show.html.haml" do
  include InvoicesHelper

  before(:each) do
    login_and_assign
    assigns[:invoice] = Factory(:invoice, :id => 42)
    assigns[:users] = [ @current_user ]
    assigns[:comment] = Comment.new
    assigns[:account] = @account= Factory(:invoice)
  end

  it "should render invoice landing page" do
    template.should_receive(:render).with(hash_including(:partial => "common/new_comment"))
    template.should_receive(:render).with(hash_including(:partial => "common/comment"))

    render "/invoices/show.html.haml"

    response.should have_tag("div[id=edit_invoice]")
  end

end

