require 'json'
require 'docsplit'
require 'fileutils'
require 'pry'
require 'dircrawl'
load '/home/user/TransparencyToolkit/gems/ParseFile/lib/ocrfile.rb' 
load '/home/user/TransparencyToolkit/gems/ParseFile/lib/extractmetadata.rb' 

class ParseFile
  def initialize(file, input_dir, output_dir, tika)
    @path = file
    @input_dir = input_dir
    @output_dir = output_dir
	# Use custom Tika URL or OKFN GiveMeText service
	if tika
	  @tika = tika
	else
	  @tika = nil
	end
  end

  # Parse the file
  def parse_file
    begin
    # Get metadata
    m = ExtractMetadata.new(@path, @input_dir, @output_dir)
    @metadata = m.extract

    # OCR File
    o = OCRFile.new(@path, @input_dir, @output_dir, @metadata[:rel_path], @tika_url)
    @text = o.ocr

    # Generate output and return
    gen_output
    rescue #TODO: Fix!
      binding.pry
    end
  end

  # Generate output
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

