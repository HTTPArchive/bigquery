require 'json'

def type(t)
  case t
  when /tinyint/ then "BOOLEAN"
  when /int/ then "INTEGER"
  when /varchar|text/ then "STRING"
  end
end

def scan(table)
  schema = []
  s = IO.read('httparchive_schema.sql')

  m = s.match(/CREATE\sTABLE\s`#{table}`\s\((.*?)PRIMARY\sKEY/m)[1]
  m.split("\n").compact.each do |f|
    next if f.strip.empty?
    fm = f.strip.match(/`(.*?)`\s(\w+)/m)

    schema << {
      "name" => fm[1],
      "type" => type(fm[2])
    }
  end

  schema
end

jj scan(ARGV[0])
