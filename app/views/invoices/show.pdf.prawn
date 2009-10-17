pdf.text "Some company name ##{@invoice.uniqueid}", :size => 30, :style => :bold
pdf.move_down(30)
pdf.text "Example basic Invoice ##{@invoice.uniqueid}", :size => 30, :style => :bold
pdf.move_down(30)
items =[[@invoice.title,@invoice.amount,@invoice.vat,@invoice.total]]
pdf.table items, :border_style => :grid,
  :row_colors => ["FFFFFF","DDDDDD"],
  :headers => ["Title", "Amount", "VAT", "Total"],
  :align => { 0 => :left, 1 => :right, 2 => :right, 3 => :right }
pdf.move_down(10)
pdf.text "Total Price: #{number_to_currency(@invoice.total)}", :size => 16, :style => :bold
pdf.text "<b>Some other text</b>", :size => 16, :style => :bold

