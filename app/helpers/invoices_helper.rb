# Fat Free CRM
# Copyright (C) 2008-2009 by Michael Dvorkin
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#------------------------------------------------------------------------------

module InvoicesHelper

  def invoice_status_checbox(status, count)
    checked = (session[:filter_by_invoice_status] ? session[:filter_by_invoice_status].split(",").include?(status.to_s) : count > 0)
    check_box_tag("status[]", status, checked, :onclick => remote_function(:url => { :action => :filter }, :with => %Q/"status=" + $$("input[name='status[]']").findAll(function (el) { return el.checked }).pluck("value")/))
  end

end
