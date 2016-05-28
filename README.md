This OCRs a file (using tika or tesseract) and returns metadata too.

To install-
gem install parsefile

This is best used with the DirCrawl gem. These are the blocks that should be
passed in if using it with DirCrawl-
block = lambda do |file, in_dir, out_dir|
  p = ParseFile.new(file, in_dir, out_dir)
  p.parse_file
end

include = lambda do
  require 'parsefile'
end
  
