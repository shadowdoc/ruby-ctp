# mirc_processor.rb
# Mirc pipeline processor
# This script aids in writing pipeline confirguration xml for the RSNA Clinical Trials processor
# Set the variables here in this script and then run it!
require 'erb'


template_file = "basic-research-pipeline.erb"

b = binding
name = "sswrist"
listening_port = 1085
listening_ip = "134.68.158.28"
destination_aet = "FRESHAIR"
destination_ip = "134.68.161.109"
destination_port = 4096

template = ERB.new(File.read(template_file))

puts template.result(b)