require_relative "../lib/pdf/core"

pdf = PDF::Core::Renderer.new(PDF::Core::DocumentState.new({}))

pdf.start_new_page
pdf.add_content("#{PDF::Core.real_params([100,500])} m")
pdf.add_content("#{PDF::Core.real_params([300,550])} l")
pdf.add_content("S")

pdf.render_file("x.pdf")
