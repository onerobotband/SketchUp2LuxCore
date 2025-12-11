# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 59 Temple
# Place - Suite 330, Boston, MA 02111-1307, USA, or go to
# http://www.gnu.org/copyleft/lesser.txt.
#-----------------------------------------------------------------------------
# This file is part of su2lux.
#
# Network Rendering Settings Editor for LuxCoreRender
# Allows deploying renderings over the network

class LuxrenderNetworkSettingsEditor

	attr_reader :network_settings_dialog
	
	##
	# Initialize the network settings editor
	##
	def initialize(scene_id, lrs)
		puts "initializing network settings editor"
		@scene_id = scene_id
		@lrs = lrs
		
		filename = File.basename(Sketchup.active_model.path)
		if (filename == "")
			windowname = "SU2LUX Network Rendering"
		else
			windowname = "SU2LUX Network Rendering - " + filename
		end
		
		@network_settings_dialog = UI::WebDialog.new(windowname, true, "LuxrenderNetworkSettingsEditor", 500, 550, 10, 10, true)
		@network_settings_dialog.max_width = 700
		@network_settings_dialog.max_height = 800
		
		setting_html_path = Sketchup.find_support_file("network_settings.html", File.join("Plugins", SU2LUX::PLUGIN_FOLDER))
		@network_settings_dialog.set_file(setting_html_path)
		
		setup_callbacks
		puts "finished initializing network settings editor"
	end
	
	##
	# Setup dialog callbacks
	##
	def setup_callbacks
		# Handle parameter changes
		@network_settings_dialog.add_action_callback("param_generate") { |dialog, params|
			pair = params.split("=")
			key = pair[0]
			value = pair[1]
			
			if (@lrs.respond_to?(key))
				method_name = key + "="
				if (value.to_s.downcase == "true")
					value = true
				elsif (value.to_s.downcase == "false")
					value = false
				end
				@lrs.send(method_name, value)
			else
				SU2LUX.dbg_p "Parameter " + key + " does not exist."
			end
		}
		
		# Handle browse for local LuxCore path
		@network_settings_dialog.add_action_callback("browse_local_luxcore") { |dialog, params|
			path = UI.openpanel("Select LuxCoreRender executable", "", "")
			if path
				path = path.gsub(/\\/, '/')
				@lrs.network_luxcore_path_local = path
				dialog.execute_script("$('#network_luxcore_path_local').val('#{path}');")
			end
		}
		
		# Handle browse for network LuxCore path
		@network_settings_dialog.add_action_callback("browse_network_luxcore") { |dialog, params|
			path = UI.openpanel("Select network LuxCoreRender path", "", "")
			if path
				path = path.gsub(/\\/, '/')
				@lrs.network_luxcore_path_network = path
				dialog.execute_script("$('#network_luxcore_path_network').val('#{path}');")
			end
		}
		
		# Handle browse for network output path
		@network_settings_dialog.add_action_callback("browse_output_path") { |dialog, params|
			path = UI.select_directory(title: "Select output directory")
			if path
				path = path.gsub(/\\/, '/')
				@lrs.network_output_path = path
				dialog.execute_script("$('#network_output_path').val('#{path}');")
			end
		}
		
		# Test connection to master node
		@network_settings_dialog.add_action_callback("test_master_connection") { |dialog, params|
			address = @lrs.network_master_address
			port = @lrs.network_master_port
			
			if address.nil? || address.empty?
				UI.messagebox("Please enter a master node address first.")
			else
				# Simple connection test
				result = test_network_connection(address, port)
				if result
					UI.messagebox("Successfully connected to master node at #{address}:#{port}")
				else
					UI.messagebox("Could not connect to master node at #{address}:#{port}\nPlease check the address and ensure LuxCoreRender is running.")
				end
			end
		}
		
		# Add slave node
		@network_settings_dialog.add_action_callback("add_slave_node") { |dialog, address|
			if address && !address.empty?
				current_slaves = @lrs.network_slave_addresses
				if current_slaves.nil? || current_slaves.empty?
					@lrs.network_slave_addresses = address
				else
					@lrs.network_slave_addresses = current_slaves + "," + address
				end
				@lrs.network_slave_count = @lrs.network_slave_count.to_i + 1
				update_slave_list(dialog)
			end
		}
		
		# Remove slave node
		@network_settings_dialog.add_action_callback("remove_slave_node") { |dialog, address|
			if address && !address.empty?
				current_slaves = @lrs.network_slave_addresses
				if current_slaves
					slaves = current_slaves.split(",").map(&:strip)
					slaves.delete(address)
					@lrs.network_slave_addresses = slaves.join(",")
					@lrs.network_slave_count = slaves.length
					update_slave_list(dialog)
				end
			end
		}
		
		# Start network render
		@network_settings_dialog.add_action_callback("start_network_render") { |dialog, params|
			start_network_render
		}
		
		# Dialog loaded callback
		@network_settings_dialog.add_action_callback("network_settings_loaded") { |dialog, params|
			sendDataFromSketchup
		}
	end
	
	##
	# Test network connection
	##
	def test_network_connection(address, port)
		begin
			require 'socket'
			socket = TCPSocket.new(address, port.to_i)
			socket.close
			return true
		rescue => e
			puts "Network connection test failed: #{e.message}"
			return false
		end
	end
	
	##
	# Update slave list in dialog
	##
	def update_slave_list(dialog)
		slaves = @lrs.network_slave_addresses
		if slaves && !slaves.empty?
			slave_array = slaves.split(",").map(&:strip)
			slave_html = slave_array.map { |s| "<div class='slave-item'>#{s} <button onclick='removeSlave(\"#{s}\")'>Remove</button></div>" }.join("")
			dialog.execute_script("$('#slave_list').html('#{slave_html}');")
			dialog.execute_script("$('#network_slave_count').val('#{slave_array.length}');")
		else
			dialog.execute_script("$('#slave_list').html('<div class=\"no-slaves\">No slave nodes configured</div>');")
			dialog.execute_script("$('#network_slave_count').val('0');")
		end
	end
	
	##
	# Start network rendering
	##
	def start_network_render
		lrs = @lrs
		
		# First export the scene
		SU2LUX.export
		
		# Build command line based on render mode
		luxcore_path = lrs.network_use_network_path ? lrs.network_luxcore_path_network : lrs.network_luxcore_path_local
		luxcore_path = lrs.export_luxrender_path if luxcore_path.nil? || luxcore_path.empty?
		
		if luxcore_path.nil? || luxcore_path.empty?
			UI.messagebox("LuxCoreRender path not configured. Please set the path in Scene Settings or Network Settings.")
			return
		end
		
		export_path = lrs.export_file_path
		
		case lrs.network_render_mode
		when 'local'
			# Simple local render
			SU2LUX.launch_luxrender
		when 'master'
			# Start as master node
			launch_as_master(luxcore_path, export_path)
		when 'slave'
			# This shouldn't be called from here typically
			UI.messagebox("Slave mode should be started on the slave machine, not from this interface.")
		end
	end
	
	##
	# Launch LuxCoreRender as master node for network rendering
	##
	def launch_as_master(luxcore_path, scene_path)
		port = @lrs.network_master_port
		threads = @lrs.network_threads_per_node
		
		if (ENV['OS'] =~ /windows/i)
			# Windows command
			thread_opt = threads > 0 ? " -t #{threads}" : ""
			command = "start \"luxcore_master\" \"#{luxcore_path}\" \"#{scene_path}\"#{thread_opt}"
			system(command)
		else
			# macOS command
			thread_opt = threads > 0 ? " -t #{threads}" : ""
			Thread.new do
				system("\"#{luxcore_path}\" \"#{scene_path}\"#{thread_opt}")
			end
		end
	end
	
	##
	# Show the dialog
	##
	def show
		@network_settings_dialog.show { sendDataFromSketchup }
	end
	
	##
	# Send data from SketchUp to the dialog
	##
	def sendDataFromSketchup
		puts "running sendDataFromSketchup from network settings editor"
		
		# List of network settings to sync
		network_settings = [
			'network_rendering_enabled',
			'network_render_mode',
			'network_master_address',
			'network_master_port',
			'network_slave_count',
			'network_luxcore_path_local',
			'network_luxcore_path_network',
			'network_use_network_path',
			'network_output_path',
			'network_threads_per_node'
		]
		
		network_settings.each { |setting|
			setValue(setting, @lrs.send(setting))
		}
		
		# Update slave list
		update_slave_list(@network_settings_dialog)
		
		# Update visibility based on render mode
		@network_settings_dialog.execute_script('update_render_mode_sections();')
	end
	
	##
	# Set value in dialog
	##
	def setValue(id, value)
		new_value = value.to_s
		
		if (@lrs.send(id) == true || @lrs.send(id) == false)
			cmd = "$('##{id}').attr('checked', #{value});"
			@network_settings_dialog.execute_script(cmd)
		else
			cmd = "$('##{id}').val('#{new_value}');"
			@network_settings_dialog.execute_script(cmd)
		end
	end
	
	##
	# Close the dialog
	##
	def close
		@network_settings_dialog.close
	end
	
	##
	# Check if dialog is visible
	##
	def visible?
		return @network_settings_dialog.visible?
	end

end
