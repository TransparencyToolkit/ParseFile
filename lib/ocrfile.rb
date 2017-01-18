require 'fileutils'
require 'docsplit'
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
      if File.exist?(@output_dir+@rel_path+".json")
        load_extracted_text(@output_dir+@rel_path+".json")
      elsif @path.include?(".pdf")
        ocr_pdf
      else
        if @tika
          give_me_text_local
        else
          give_me_text
        end
      end
    rescue # Detect errors
      binding.pry
    end
    
    return @text
  end

  # Check if file is pdf
  def is_pdf?
    puts "determined: is_pdf"
    file_start = File.open(@path, 'r') { |f| f.read(8)}
    file_start.match(/\%PDF-\d+\.?\d+/)
  end

  # Load text that is already extracted
  def load_extracted_text(file)
	puts "file exists: load_extracted_text"
    @text = JSON.parse(File.read(file))["text"]
  end

  # Send file to give me text
  def give_me_text
	puts "using: give_me_text"
    c = Curl::Easy.new("http://givemetext.okfnlabs.org/tika/tika/form")
    c.multipart_form_post = true
    c.http_post(Curl::PostField.file('file', @path))

	@text = c.body_str
    gotten_text_ok?(@text)
  end

  def give_me_text_local
	puts "using: give_me_text_local"
	c = Curl::Easy.new(@tika + "/tika")
	# TODO: move this mime filtering to a higher global level
	mime_magic = MimeMagic.by_path(@path)
	file_data = File.read(@path)
	c.headers['Content-Type'] = mime_magic.type
	c.headers['Accept'] = "text/plain"
	c.http_put(file_data)

	#binding.pry
	@text = c.body_str
	gotten_text_ok?(@text)
  end

  # Checks if text was successfully extracted
  def gotten_text_ok?(text)
    throw :extraction_error if text.include?("java.io.IOException: Stream Closed")
  end

  # OCR with tesseract
  def ocr_pdf
	puts "using: ocr_pdf"
    # Dir_paths
    base = Dir.pwd+"/"
    
    # Split pages to handle large PDFs
    Docsplit.extract_pages(@path, :output => base+'pages')
    filename = @path.split("/").last.gsub(".pdf", "")
    docs = Dir[base+'pages/'+filename+'*']

    # Rename pages so that they can be processed with spaces
    docs.each do |d|
      new_name = d.split("/").last.gsub(" ", "_").gsub("(", "").gsub(")", "")
      File.rename(d, base+'pages/'+new_name)
    end
    filename = filename.gsub(" ", "_").gsub("(", "").gsub(")", "")
    docs_no_spaces = Dir[base+'pages/'+filename+'*']
    
    # Extract text and save
    Docsplit.extract_text(docs_no_spaces, :output => base+'text')
    text_files = Dir[base+'text/'+filename+'*']
    sorted_text = text_files.sort_by {|f|
		f.split(filename).last.gsub("_", "").gsub(".txt", "").to_i }
    sorted_text.each do |f|
      @text += File.read(f)
    end

    # Clean up
    FileUtils.rm_f Dir.glob(base+"pages/*")
    Dir.delete(base+"pages")
    FileUtils.rm_f Dir.glob(base+"text/*")
    Dir.delete(base+"text")
  end
end
