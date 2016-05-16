require 'json'
require 'docsplit'

class ExtractMetadata
  def initialize(file, input_dir, output_dir)
    @path = file
    @input_dir = input_dir
    @output_dir = output_dir
  end

  # Extract metadata
  def extract
    outhash = Hash.new
    
    # Get relative path
    @rel_path = get_rel_path
    outhash[:rel_path] = @rel_path
    outhash[:folders] = get_folders

    # Get formatted name and file type
    outhash[:formatted_name] = get_formatted_name
    outhash[:filetype] = get_file_type

    # Extract file metadata, merge. and return
    begin
      outhash.merge!(extract_file_metadata)
    rescue
    end
    return outhash
  end

  # Split relative path and get array of directories
  def get_folders
    folders = @rel_path.split("/")

    # Remove file and empty items
    folders.delete(folders.last)
    folders.delete("")

    return folders
  end

  # Get the relative path
  def get_rel_path
    @path.gsub(@input_dir, "")
  end

  # Get a formatted file name
  def get_formatted_name
    @rel_path.split(".").first.gsub("_", " ").gsub("/", "")
  end

  # Get file type
  def get_file_type
    @rel_path.split(".").last
  end

  # Extract PDF metadata
  def extract_file_metadata
    metadata = Hash.new
    metadata[:author] = Docsplit.extract_author(@path)
    metadata[:creator] =  Docsplit.extract_creator(@path)
    metadata[:producer] = Docsplit.extract_producer(@path)
    metadata[:title] = Docsplit.extract_title(@path)
    metadata[:subject] = Docsplit.extract_subject(@path)
    metadata[:date] = Docsplit.extract_date(@path)
    metadata[:keywords] = Docsplit.extract_keywords(@path)
    metadata[:length] = Docsplit.extract_length(@path)
    return metadata
  end
end
