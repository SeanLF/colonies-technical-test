module JsonFileManipulation
  require 'json'

  def get_json_from_file(filename)
    file = File.read(filename)
    JSON.parse(file)
  end

  def write_json_to_file(data, filename)
    File.open(filename, 'w') { |f| f.write(data.to_json) }
  end
end
