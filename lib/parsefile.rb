require 'json'
require 'fileutils'
require 'pry'
require 'ocrfile' 
require 'extractmetadata' 

class ParseFile
  def initialize(file, input_dir, output_dir, tika)
    @path = file
    @input_dir = input_dir
    @output_dir = output_dir
	# Pass URL of a Tika server
	if tika
	  @tika = tika
	# Use OKFNs service over normal HTTP... ZOMG... O.o
	else
	  @tika = nil
	end
  end

  def parse_file
    begin
	  puts "sending file: " + @path

      m = ExtractMetadata.new(@path, @input_dir, @output_dir)
      @metadata = m.extract

      o = OCRFile.new(@path, @input_dir, @output_dir, @metadata[:rel_path], @tika)
      @text = o.ocr

      gen_output
    rescue
	  #TODO: use a global debug / log
      binding.pry
    end
  end

  def gen_output
    outhash = Hash.new
    outhash[:full_path] = @path
    outhash.merge!(@metadata)
    begin
      outhash[:text] = @text.to_s.encode('UTF-8', {
                                           :invalid => :replace,
                                           :undef   => :replace,
                                           :replace => '?'
                                         })
      return JSON.pretty_generate(outhash)
    rescue
      binding.pry
    end
  end
end

