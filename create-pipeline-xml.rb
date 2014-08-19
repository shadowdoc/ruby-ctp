# create-pipeline-xml.rb
# Mirc pipeline processor
# This script aids in writing pipeline confirguration xml for the RSNA Clinical Trials processor
# Set the variables here in this script and then run it!
require 'erb'

ROOT_BASE = "roots/"

@name = "cachexia"

def render_template(t)
	# This method takes a template file as an argument and puts the output to the console

	b = binding
	template = ERB.new(File.read(File.join(Dir.pwd, t)))

	output = template.result(b).gsub /^$\n/, ''
	puts output
end

def pipeline
	@calling_aet = "IUSM_CACHEXIA"
	@listening_port = 1086
	@listening_ip = "134.68.158.28"

	# destination_aet = "FRESHAIR"
	# destination_ip = "134.68.161.109"
	# destination_port = 4096

	@destination_aet = "CHSYNRSRCHSCP"
	@destination_ip = "10.8.224.44"
	@destination_port = 104
	render_template('pipelines/basic-research-pipeline.erb')
end

def file_storage_service
	###################
	# File Storage Service config
	###################

	file_service_root = File.join(ROOT_BASE, @name + "DicomAnon", "FileStorageService")
	file_service_web_port = nil

	render_template('stages/file_storage_service.erb')

end

def directory_storage_service

	@directory_service_root = File.join(ROOT_BASE, @name + "DicomAnon", "DirectoryStorageService")
	@structure = "(0010,0020) - (0010,0030)/[00080020]"

	render_template('stages/directory_storage_service.erb')

end

pipeline
directory_storage_service

