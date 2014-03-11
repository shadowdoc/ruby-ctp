# mirc_processor.rb
# Mirc pipeline processor
# This script aids in writing pipeline confirguration xml for the RSNA Clinical Trials processor
# Set the variables here in this script and then run it!
require 'erb'

if ARGV.length != 0 && File.exists?(ARGV[0])
	template_file = ARGV[0]
else
	raise "Must supply a valid .erb file as an argument"
end

root_base = "roots/"

b = binding
name = "research"
calling_aet = "sswrist"
listening_port = 1085
listening_ip = "134.68.158.28"

# destination_aet = "FRESHAIR"
# destination_ip = "134.68.161.109"
# destination_port = 4096

destination_aet = "CHSYNRSRCHSCP"
destination_ip = "10.8.224.44"
destination_port = 104


###################
# File Storage Service config
###################

file_service_root = File.join(root_base, name + "DicomAnon", "FileStorageService")
file_service_web_port = nil

template = ERB.new(File.read(template_file))

output = template.result(b).gsub /^$\n/, ''
puts output