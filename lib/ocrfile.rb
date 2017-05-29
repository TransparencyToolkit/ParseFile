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
	@allowed_files = [
		'application/x-mobipocket-ebook',
		'application/epub+zip',
		'application/rtf',
		'application/vnd.ms-works',
		'application/msword',
		'application/x-download',
		'message/rfc822',
		'text/x-log',
		'text/scriptlet',
		'text/plain',
		'text/iuls',
		'text/plain',
		'text/richtext',
		'text/x-setext',
		'text/x-component',
		'text/webviewhtml',
		'text/h323',
		'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
		'application/vnd.oasis.opendocument.text',
		'application/vnd.oasis.opendocument.text-template',
		'application/vnd.sun.xml.writer',
		'application/vnd.sun.xml.writer.template',
		'application/vnd.sun.xml.writer.global',
		'application/vnd.stardivision.writer',
		'application/vnd.stardivision.writer-global',
		'application/x-starwriter',
		'application/excel',
		'application/msexcel',
		'application/vnd.ms-excel',
		'application/vnd.msexcel',
		'application/csv',
		'application/x-csv',
		'text/tab-separated-values',
		'text/x-comma-separated-values',
		'text/comma-separated-values',
		'text/csv',
		'text/x-csv',
		'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
		'application/vnd.oasis.opendocument.spreadsheet',
		'application/vnd.oasis.opendocument.spreadsheet-template',
		'application/vnd.sun.xml.calc',
		'application/vnd.sun.xml.calc.template',
		'application/vnd.stardivision.calc',
		'application/x-starcalc',
		'image/png',
		'image/jpeg',
		'image/cis-cod',
		'image/ief',
		'image/pipeg',
		'image/tiff',
		'image/x-cmx',
		'image/x-cmu-raster',
		'image/x-rgb',
		'image/x-icon',
		'image/x-xbitmap',
		'image/x-xpixmap',
		'image/x-xwindowdump',
		'image/x-portable-anymap',
		'image/x-portable-graymap',
		'image/x-portable-pixmap',
		'image/x-portable-bitmap',
		'image/svg+xml',
		'application/x-photoshop',
		'application/postscript',
		'application/powerpoint',
		'application/vnd.ms-powerpoint',
		'application/vnd.oasis.opendocument.presentation',
		'application/vnd.oasis.opendocument.presentation-template',
		'application/vnd.openxmlformats-officedocument.presentationml.presentation',
		'application/vnd.sun.xml.impress',
		'application/vnd.sun.xml.impress.template',
		'application/vnd.stardivision.impress',
		'application/vnd.stardivision.impress-packed',
		'application/x-starimpress'
	]
  end

  # OCR file
  def ocr
    begin
	  mime_magic = MimeMagic.by_path(@path)
      if File.exist?(@output_dir+@rel_path+".json")
        load_extracted_text(@output_dir+@rel_path+".json")
      elsif mime_magic.type == "application/pdf"
        ocr_pdf
      elsif (@allowed_files.include? mime_magic.type) 
        if @tika
          give_me_text_local(mime_magic)
        else
          give_me_text
        end
	  else
		puts "file type not allowed: " + mime_magic.type
      end
    rescue
	  # Detect errors
      # binding.pry
    end
    
    return @text
  end

  # Check if file is pdf
  def is_pdf?
    puts "determined is_pdf"
    file_start = File.open(@path, 'r') { |f| f.read(8)}
    file_start.match(/\%PDF-\d+\.?\d+/)
  end

  # Load text that is already extracted
  def load_extracted_text(file)
	puts "file already exists"
    @text = JSON.parse(File.read(file))["text"]
  end

  # Send file to give me text
  def give_me_text
	puts "send to OKFNs server"
    c = Curl::Easy.new("http://givemetext.okfnlabs.org/tika/tika/form")
    c.multipart_form_post = true
    c.http_post(Curl::PostField.file('file', @path))

	@text = c.body_str
    gotten_text_ok?(@text)
  end

  def give_me_text_local(mime_magic)
	puts "send to Tika server: " + @tika
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

  # OCR with tesseract
  def ocr_pdf
	puts "using normal ocr_pdf"
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
