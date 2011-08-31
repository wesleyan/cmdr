fork {
	`sass --watch sass/:static/css/`
}

# compile all of the coffee files
text = ""
File.open "#{File.dirname(__FILE__)}/static/index.html", "r" do |f|
	replace = Dir.glob("#{File.dirname(__FILE__)}/script/**/*.coffee").collect{|name|
		"<script src='dev/#{name.gsub(".coffee", ".js").gsub("./script/", "")}'></script>"
	}.join("\n")
	text = f.read
	text.gsub!(/(?<=APPLICATION\_SCRIPTS\_BEGIN --\>\n).*(?=\<!-- APPLICATION\_SCRIPTS\_END)/, replace)
end

File.open "#{File.dirname(__FILE__)}/static/index.html", "w+" do |f|
	f.write(text)
end

`coffee --lint --watch --output static/dev script/`
