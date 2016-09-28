require 'yajl'
require 'zlib'
require 'open3'
require 'nokogiri'
require 'optparse'
require 'domainatrix'

ROOT_PATH = '/'
WWW = 'www'
matched = 0
res, options = {}, {}

ARGV << "-h" if ARGV.empty?
OptionParser.new do |opts|
  opts.banner = "Usage: process.rb [options]"

  opts.on('-a', '--alexa=file', 'Alexa input data') do |v|
    options[:alexa] = v
  end

  opts.on('-d', '--dmoz=file', 'DMOZ input data') do |v|
    options[:dmoz] = v
  end

  opts.on('-o', '--output=file', 'Output file') do |v|
    options[:output] = v || 'urls.json.gz'
  end

  opts.on('-h', '--help') do
    puts opts
    exit
  end
end.parse!

if options[:alexa].nil? or options[:dmoz].nil?
  raise OptionParser::MissingArgument
end

puts "Loading Alexa data..."
IO.popen("unzip -p #{options[:alexa]}", 'rb') do |io|
  io.each do |line|
    rank, name = line.strip.split(',')
    res[name] = {
        alexa_domain: name,
        alexa_rank: rank.to_i,
        dmoz_topic: []
    }
  end
end

puts "Loading DMOZ data..."
Zlib::GzipReader.open(options[:dmoz]) do |gz|
  Nokogiri::XML::Reader(gz).each do |node|
    #
    # <ExternalPage about="http://animation.about.com/">
    # <d:Title>About.com: Animation Guide</d:Title>
    #   <d:Description>Keep up with developments in online animation for all skill levels. Download tools, and seek inspiration from online work.</d:Description>
    # <topic>Top/Arts/Animation</topic>
    # </ExternalPage>
    #
    if node.name == 'ExternalPage' && node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
      page = Nokogiri::XML(node.outer_xml).at('ExternalPage')

      url = Domainatrix.parse(page.attribute('about').text)
      next unless url.path == ROOT_PATH
      next unless url.subdomain.empty? or url.subdomain == WWW
      next if url.url.include? '?' or url.url.include? '#'

      if data = res[url.domain + "." + url.public_suffix]
        matched += 1
        data[:dmoz_topic] << page.at('topic').text
        data[:dmoz_url] ||= page.attribute('about').text
        data[:dmoz_title] ||= page.xpath('//d:Title').text
        data[:dmoz_description] ||= page.xpath('//d:Description').text
      end
    end
  end

end

File.open('urls.json.gz', 'w') do |f|
  gz = Zlib::GzipWriter.new(f)
  res.each_value do |val|
    gz.puts Yajl::Encoder.encode(val)
  end
  gz.close
end

puts "Done. Matched #{matches} DMOZ domains."

