require_relative "../lib/pdf/core"

pdf = PDF::Core::Renderer.new(PDF::Core::DocumentState.new({}))

pdf.start_new_page
pdf.add_content("%.3f %.3f m" % [100, 500])
pdf.add_content("%.3f %.3f l" % [300, 550])
pdf.add_content("S")

pdf.render_file("x.pdf")
