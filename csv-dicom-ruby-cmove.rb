# csv-dicom-ruby-cmove.rb
# 
# A ruby script that wraps that performs C-move operations based on a csv file
# of accession numbers using the ruby-dicom toolkit
#
# usage: ruby csv-dicom-ruby-cmove.rb <filename> <column (defaults to zero)>
# Marc Kohli marckohli@gmail.com

require 'csv'
require 'dicom'

# Setup the destination SCP info here.
DESTINATION_AET = "CTPRESEARCH"
DESTINATION_HOST = "134.68.158.28"
DESTINATION_PORT = 1082

# Setup our source PACS info here
SOURCE_AET = "CHSYNPRODSCP"
SOURCE_HOST = "10.8.224.54" # specific dicom server
#SOURCE_HOST = "10.8.224.120" # content switch
SOURCE_PORT = 104

DEBUG = true

REST = 2 * 60

if ARGV.length == 0 || !File.exists?(ARGV[0])
	raise "ERROR: Include a valid .csv file as the first command line argument"
end

log = Logger.new(ARGV[0] + ".log")

source = DICOM::DClient.new(SOURCE_HOST, SOURCE_PORT, :ae => DESTINATION_AET, :host_ae => SOURCE_AET, :timeout => 10000)

# Make sure the destination listener is running
destination = DICOM::DClient.new(DESTINATION_HOST, DESTINATION_PORT, :ae => 'test', :host_ae => DESTINATION_AET)

###########################
# Here is where the script really starts
###########################

start_time = Time.now
puts "Start Time: #{start_time}"

CSV.foreach(ARGV[0]) do |row|

	# Make sure that both destinations are really up.  If either is down they will throw an
	# error and script execution will stop

	puts "Testing C-ECHO of source: #{source.host_ae}\n******************************************\n"
	source.echo

	puts "Testing C-ECHO of destination: #{destination.host_ae}\n******************************************\n"
	destination.echo

	# CSV format assumes that your accession number is in the first column
	# if the second command line argument is not provided

	column = 0 || ARGV[1]

	accession_number = row[column]

	puts "Trying to Move AccessionNumber: #{accession_number}\n"

	study = source.find_studies('0008,0050' => accession_number).first

	if study.nil?
		# This means that there are no images for this accession number
		# We will log this event to a file
		log.error { "No images found for Accession Number: #{accession_number}" }
	else

		puts "StudyUID Found: #{study['0020,000D']}\n"

	    source.move_study(DESTINATION_AET, '0008,0050' => accession_number, '0020,000D' => study['0020,000D'])
	    
	    puts "Sleeping: #{REST} seconds." 

	    sleep REST

	end


end

end_time = Time.now
puts "End Time: #{end_time}"
puts "Run Time = #{(end_time - start_time)/60/60} hours"
log.close