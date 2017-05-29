require 'fileutils'
require 'curb'
require 'mimemagic'

class OCRFile
  def initialize(file, input_dir, output_dir, rel_path, tika)
    @path = file
    @input_dir = input_dir
    @output_dir = output_dir
    @rel_path = rel_path
	@tika = tika
    @text = ""
  end

  # OCR file
  def ocr
    begin
	  mime_magic = MimeMagic.by_path(@path)
      if File.exist?(@output_dir+@rel_path+".json")
        load_extracted_text(@output_dir+@rel_path+".json")
      else
        if @tika
          give_me_text_local(mime_magic)
        else
          give_me_text
        end
      end
    rescue
	  # Detect errors
      # binding.pry
      error_file = @path + "\n"
      IO.write(@output_dir+"/error_log.txt", error_file, mode: 'a')
    end
    
    return @text
  end

  # Load text that is already extracted
  def load_extracted_text(file)
	puts "file already exists"
    @text = JSON.parse(File.read(file))["text"]
  end

  # Send file to give me text
  def give_me_text
    c = Curl::Easy.new("http://givemetext.okfnlabs.org/tika/tika/form")
    c.multipart_form_post = true
    c.http_post(Curl::PostField.file('file', @path))

	@text = c.body_str
    gotten_text_ok?(@text)
  end

  def give_me_text_local(mime_magic)
	c = Curl::Easy.new(@tika + "/tika")
	file_data = File.read(@path)
	c.headers['Content-Type'] = mime_magic.type
	c.headers['Accept'] = "text/plain"
	c.http_put(file_data)

	@text = c.body_str
	gotten_text_ok?(@text)
  end

  # Checks if text was successfully extracted
  def gotten_text_ok?(text)
    throw :extraction_error if text.include?("java.io.IOException: Stream Closed")
  end

end
