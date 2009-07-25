#!/usr/bin/env ruby
require 'rubygems'
require 'hpricot'

SVG = "projector.svg"
SMALL_WIDTH = 57
LARGE_WIDTH = 195


def make_png(width, height, location, name)
	size_string = ""
	size_string += " --export-width=#{width}" if width
	size_string += " --export-height=#{height}" if height
	
	location = "#{location}/" unless location[-1] == "/"[0]
	command = %Q\inkscape --without-gui --export-png="#{location}#{name}.png" #{size_string} projector_temp.svg\
	puts command
	Kernel.system(command)
end
def make_both_pngs(name)
	make_png(SMALL_WIDTH, nil, "../button", name)
	make_png(LARGE_WIDTH, nil, "../large", name)
end

doc = open(SVG){|f| Hpricot.XML(f)}
File.open("projector_temp.svg", "w+"){|f| f.write(doc.to_s)}

#the svg stats out as the on image
make_both_pngs("onState")

#next we make the cooling image
doc.at("#tspan7950").inner_html = "Cooling"
doc.at("#tspan7950").set_attribute("style", "font-size:24px;opacity:1;fill:#808080;")
doc.at("#textPath3253").set_attribute("startOffset", "0%")
doc.at("#stop8014").set_attribute("style", "stop-color:#2e5f9f;stop-opacity:1;")
doc.at("#stop8016").set_attribute("style", "stop-color:#2e5f9f;stop-opacity:0;")
File.open("projector_temp.svg", "w+"){|f| f.write(doc.to_s)}
make_both_pngs("coolingState")

#and warming
doc.at("#tspan7950").inner_html = "Warming"
doc.at("#tspan7950").set_attribute("style", "font-size:20px;opacity:1;fill:#808080;")
doc.at("#stop8014").set_attribute("style", "stop-color:#9F0C00;stop-opacity:1;")
doc.at("#stop8016").set_attribute("style", "stop-color:#9F0C00;stop-opacity:0;")

File.open("projector_temp.svg", "w+"){|f| f.write(doc.to_s)}
make_both_pngs("warmingState")

#and off
doc.at("#tspan7950").inner_html = "OFF"
doc.at("#tspan7950").set_attribute("style", "font-size:36px;opacity:1;fill:#808080;")
doc.at("#textPath3253").set_attribute("startOffset", "7%")
doc.at("#stop8014").set_attribute("style", "stop-color:#9F0C00;stop-opacity:0;")

File.open("projector_temp.svg", "w+"){|f| f.write(doc.to_s)}
make_both_pngs("offState")

#and mute
doc.at("#tspan7950").inner_html = "Mute"
doc.at("#textPath3253").set_attribute("startOffset", "3%")
doc.at("#path3942").set_attribute("style", "fill:#870000;fill-rule:evenodd;stroke:#870000;stroke-width:2;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1;fill-opacity:1;stroke-miterlimit:4;stroke-dasharray:none")
doc.at("#path8836").set_attribute("style", "opacity:1;fill:#ff0000;fill-opacity:0.39016395;stroke:#870000;stroke-width:1.85474885;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1")

File.open("projector_temp.svg", "w+"){|f| f.write(doc.to_s)}
make_both_pngs("muteState")

