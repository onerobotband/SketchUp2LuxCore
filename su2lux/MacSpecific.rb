class OSSpecific

	attr_reader :variables
	alias_method :get_variables, :variables
	
	##
	# Initialize OS-specific variables for macOS
	# Updated for LuxCoreRender compatibility on macOS 15.7.2 and SketchUp 2018
	##
	def initialize
		@variables = {
			"default_save_folder" => File.expand_path("~"),
			# Legacy key name "luxrender_filename" retained for backward compatibility
			# Now points to LuxCoreRender executable (luxcoreui)
			"luxrender_filename" => "luxcoreui",
            "file_appendix" => "",
            "luxconsole_filename" => "luxcoreconsole",
			"path_separator" => "/",
			"material_preview_path" => File.expand_path("~/Library/Application Support") + "/LuxCoreRender/",
            "settings_path" => File.expand_path("~/Library/Application Support") + "/LuxCoreRender/LuxCoreRender_settings_presets/",
			# Network rendering settings
			"network_config_path" => File.expand_path("~/Library/Application Support") + "/LuxCoreRender/network_config/"
		}
	end
	
	##
	# Search for LuxCoreRender installations on macOS
	##
	def search_multiple_installations
		luxcore_folder = []
		if (SU2LUX.get_os == :mac)
			# Search in common installation locations
			search_locations = [
				"/Applications",
				File.expand_path("~/Applications"),
				"/usr/local/bin",
				"/opt/local/bin"
			]
			
			search_locations.each do |start_folder|
				next unless File.directory?(start_folder)
				
				begin
					applications = Dir.entries(start_folder)
					applications.each { |app|
						# Match both LuxCoreRender and LuxCore patterns
						luxcore_folder.push(File.join(start_folder, app)) if app =~ /luxcore/i
					}
				rescue Errno::EACCES
					# Skip directories we don't have permission to read
					next
				end
			end
			
			if luxcore_folder.length > 1
				paths = luxcore_folder.join("|")
				input = UI.inputbox(["folder"], [luxcore_folder[0]], [paths], "Select LuxCoreRender folder")
				return input[0] if input
			elsif luxcore_folder.length == 1
				return luxcore_folder[0]
			else
				return nil
			end
		end
		return nil
	end # END search_multiple_installations
	
	##
	# Get the path to luxcoreui executable
	##
	def get_luxcoreui_path
		# Check common locations for luxcoreui
		possible_paths = [
			"/Applications/LuxCoreRender/luxcoreui",
			"/Applications/luxcoreui",
			"/usr/local/bin/luxcoreui",
			"/opt/local/bin/luxcoreui",
			File.expand_path("~/Applications/LuxCoreRender/luxcoreui")
		]
		
		possible_paths.each do |path|
			return path if File.exist?(path)
		end
		
		return nil
	end
	
	##
	# Check if a network path is accessible (for network rendering)
	##
	def network_path_accessible?(path)
		return false if path.nil? || path.empty?
		
		# Check if path is a network path (starts with /Volumes/ or smb:// etc.)
		if path.start_with?("/Volumes/") || path.start_with?("smb://") || path.start_with?("afp://")
			return File.exist?(path) || File.directory?(File.dirname(path))
		end
		
		return File.exist?(path)
	end

end