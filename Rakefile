require 'XcodePages'
require 'nokogiri'

desc 'Compiles HTML documentation using Doxygen'
task :doxygen do
  ENV['PROJECT_NAME'] ||= File.basename(Dir.pwd)
  XcodePages.doxygen

  # Monkey-patch the index.html because Doxygen cannot handle Markdown with an
  # image element nested within an anchor element: Markdown formatted like
  # [![text](uri)](uri). Instead, it dumps the Markdown as text. Replace this
  # text with an image element carrying the appropriate source, alternative text
  # and style.
  doc_path = File.join(XcodePages.output_directory, 'html', 'index.html')
  doc = Nokogiri::HTML.parse(open(doc_path))
  a = doc.xpath('//a[starts-with(., "![Build Status]")]').first
  text = a.children.first
  img = Nokogiri::XML::Element.new('img', doc)
  text.replace(img)
  text.content =~ /!\[(.+)\]\((.+)\)/
  img['src'] = $2
  img['alt'] = $1
  img['style'] = 'max-width:100%;'
  open(doc_path, 'w') do |f|
    f.write(doc.serialize)
  end
end

desc 'Compiles DocSet documentation using AppleDoc'
task :appledoc do
  mvers = %x(agvtool mvers -terse1).chomp
  %x(appledoc --project-version #{mvers} .)
end
