class OSSpecific

	attr_reader :variables
	alias_method :get_variables, :variables
	
	##
	# Initialize OS-specific variables for Windows
	# Updated for LuxCoreRender compatibility and SketchUp 2018
	##
	def initialize
		@variables = {
			"default_save_folder" => ENV["USERPROFILE"].gsub(File::ALT_SEPARATOR,File::SEPARATOR),
			# Legacy key name "luxrender_filename" retained for backward compatibility
			# Now points to LuxCoreRender executable (luxcoreui.exe)
			"luxrender_filename" => "luxcoreui.exe",
            "luxconsole_filename" => "luxcoreconsole.exe",
			"path_separator" => "\\",
			"material_preview_path" => File.join(ENV['APPDATA'], "LuxCoreRender").gsub(File::ALT_SEPARATOR,File::SEPARATOR),
            "settings_path" => File.join(ENV['APPDATA'],"LuxCoreRender","LuxCoreRender_settings_presets").gsub(File::ALT_SEPARATOR,File::SEPARATOR),
			# Network rendering settings
			"network_config_path" => File.join(ENV['APPDATA'],"LuxCoreRender","network_config").gsub(File::ALT_SEPARATOR,File::SEPARATOR)
		}
	end
	
	##
	# Search for LuxCoreRender installations on Windows
	##
	def search_multiple_installations
		luxcore_folder = []
		
		# Search in common installation locations
		search_locations = [
			"C:\\Program Files\\LuxCoreRender",
			"C:\\Program Files (x86)\\LuxCoreRender",
			File.join(ENV['LOCALAPPDATA'], "LuxCoreRender"),
			File.join(ENV['USERPROFILE'], "LuxCoreRender")
		]
		
		search_locations.each do |folder|
			if File.directory?(folder)
				luxcore_folder.push(folder)
			end
		end
		
		if luxcore_folder.length > 1
			paths = luxcore_folder.join("|")
			input = UI.inputbox(["folder"], [luxcore_folder[0]], [paths], "Select LuxCoreRender folder")
			return input[0] if input
		elsif luxcore_folder.length == 1
			return luxcore_folder[0]
		end
		
		return nil
	end
	
	##
	# Get the path to luxcoreui executable
	##
	def get_luxcoreui_path
		# Check common locations for luxcoreui.exe
		possible_paths = [
			"C:\\Program Files\\LuxCoreRender\\luxcoreui.exe",
			"C:\\Program Files (x86)\\LuxCoreRender\\luxcoreui.exe",
			File.join(ENV['LOCALAPPDATA'], "LuxCoreRender", "luxcoreui.exe"),
			File.join(ENV['USERPROFILE'], "LuxCoreRender", "luxcoreui.exe")
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
		
		# Check if path is a network path (UNC path)
		if path.start_with?("\\\\") || path.include?("://")
			begin
				return File.exist?(path) || File.directory?(File.dirname(path))
			rescue
				return false
			end
		end
		
		return File.exist?(path)
	end

end