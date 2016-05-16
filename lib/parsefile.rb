require 'json'
require 'docsplit'
require 'fileutils'
require 'pry'
require 'dircrawl'
load 'ocrfile.rb' 
load 'extractmetadata.rb' 

class ParseFile
  def initialize(file, input_dir, output_dir)
    @path = file
    @input_dir = input_dir
    @output_dir = output_dir
  end

  # Parse the file
  def parse_file
    begin
    # Get metadata
    m = ExtractMetadata.new(@path, @input_dir, @output_dir)
    @metadata = m.extract

    # OCR File
    o = OCRFile.new(@path, @input_dir, @output_dir, @metadata[:rel_path])
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

