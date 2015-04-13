def get_file_as_string(filename)
  data = ''
  f = File.open(filename, "r")
  f.each_line do |line|
    data += line
  end

  return data
end

def find_and_increment_version_number_with_key(key, infoplist)

  start_of_key = infoplist.index(key)
  start_of_value = infoplist.index("<string>", start_of_key) + "<string>".length
  end_of_value = infoplist.index("</string>", start_of_value)
  old_value = infoplist[start_of_value, end_of_value - start_of_value]

  print "Old version for " + key + ": " + old_value + "\n"
  print old_value.class.to_s + "\n"
  old_value_int = old_value.to_i
  print old_value_int.class.to_s + "\n"
  if (old_value.index(".") != nil) # release dot version
    parts = old_value.split(".")
    last_part = parts.last.to_i
    last_part = last_part + 1
    parts.pop

    new_version = ""
    first = true
    parts.each do |one_part|
      new_version = new_version + one_part + "."
    end

    new_version = new_version.to_s + last_part.to_s
    print "New version: " + new_version.to_s + "\n"
    new_key = "<string>#{new_version}</string>"
    infoplist = "#{infoplist[0, start_of_value - '<string>'.length]}#{new_key}#{infoplist[end_of_value + '</string>'.length, infoplist.length - (end_of_value+1)]}"

  elsif (old_value.to_i != nil) # straight integer build number
    new_version = old_value.to_i + 1
    print "New version: " + new_version.to_s + "\n"
    new_key = "<string>#{new_version}</string>"

    part_1 = infoplist[0, start_of_value - '<string>'.length]
    part_2 = new_key
    part_3 = infoplist[end_of_value + "</string>".length, infoplist.length - (end_of_value+1)]
    infoplist = part_1 + part_2 + part_3
  end

  infoplist
end


print " incrementing build numbers\n"
plist_filename = ENV['PLIST_DIR']

infoplist = get_file_as_string(plist_filename)
infoplist = find_and_increment_version_number_with_key("CFBundleVersion", infoplist)
File.open(plist_filename, 'w') {
    |f| f.write(infoplist)
  }
