require 'fileutils'
require 'docsplit'
require 'curb'

class OCRFile
  def initialize(file, input_dir, output_dir, rel_path)
    @path = file
    @input_dir = input_dir
    @output_dir = output_dir
    @rel_path = rel_path
    @text = ""
  end

  # OCR file
  def ocr
    begin
      if File.exist?(@output_dir+@rel_path)
        load_extracted_text(@output_dir+@rel_path)
      elsif @path.include?(".pdf")
        ocr_pdf
      else
        give_me_text
      end
    rescue # Detect errors
      binding.pry
    end

    return @text
  end

  # Check if file is pdf
  def is_pdf?
    file_start = File.open(@path, 'r') { |f| f.read(8)}
    file_start.match(/\%PDF-\d+\.?\d+/)
  end

  # Load text that is already extracted
  def load_extracted_text(file)
    @text = File.read(file)
  end

  # Send file to give me text
  def give_me_text
    c = Curl::Easy.new("http://givemetext.okfnlabs.org/tika/tika/form")
    c.multipart_form_post = true
    c.http_post(Curl::PostField.file('file', @path))
    @text = c.body_str
    gotten_text_ok?(@text)
  end

  # Checks if text was successfully extracted
  def gotten_text_ok?(text)
    throw :extraction_error if text.include?("java.io.IOException: Stream Closed")
  end

  # OCR with tesseract
  def ocr_pdf
    # Split pages to handle large PDFs
    Docsplit.extract_pages(@path, :output => 'pages')
    filename = @path.split("/").last.gsub(".pdf", "")
    docs = Dir['pages/'+filename+'*']

    # Extract text and save
    Docsplit.extract_text(docs, :output => 'text')
    text_files = Dir['text/'+filename+'*']
    sorted_text = text_files.sort_by {|f| f.split(filename).last.gsub("_", "").gsub(".txt", "").to_i }
    sorted_text.each do |f|
      @text += File.read(f)
    end

    # Clean up
    FileUtils.rm_f Dir.glob("pages/*")
    Dir.delete("pages")
    FileUtils.rm_f Dir.glob("text/*")
    Dir.delete("text")
  end
end
