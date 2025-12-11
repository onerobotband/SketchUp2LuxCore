// Network Settings JavaScript for SU2LUX
// Handles network rendering configuration UI

$(document).ready(function() {
    // Notify Ruby that the dialog has loaded
    window.location = 'skp:network_settings_loaded';
    
    // Setup event handlers
    setupEventHandlers();
    
    // Initialize UI state
    update_render_mode_sections();
});

function setupEventHandlers() {
    // Network rendering enabled checkbox
    $('#network_rendering_enabled').change(function() {
        var enabled = $(this).is(':checked');
        window.location = 'skp:param_generate=network_rendering_enabled=' + enabled;
        update_render_mode_sections();
    });
    
    // Render mode selection
    $('#network_render_mode').change(function() {
        var mode = $(this).val();
        window.location = 'skp:param_generate=network_render_mode=' + mode;
        update_render_mode_sections();
    });
    
    // Use network path checkbox
    $('#network_use_network_path').change(function() {
        var useNetwork = $(this).is(':checked');
        window.location = 'skp:param_generate=network_use_network_path=' + useNetwork;
        if (useNetwork) {
            $('.network_path_section').show();
        } else {
            $('.network_path_section').hide();
        }
    });
    
    // Browse buttons
    $('#browse_local_luxcore').click(function() {
        window.location = 'skp:browse_local_luxcore';
    });
    
    $('#browse_network_luxcore').click(function() {
        window.location = 'skp:browse_network_luxcore';
    });
    
    $('#browse_output_path').click(function() {
        window.location = 'skp:browse_output_path';
    });
    
    // Add slave button
    $('#add_slave_button').click(function() {
        var address = $('#new_slave_address').val();
        if (address && address.trim() !== '') {
            window.location = 'skp:add_slave_node=' + encodeURIComponent(address.trim());
            $('#new_slave_address').val('');
        }
    });
    
    // Allow adding slave with Enter key
    $('#new_slave_address').keypress(function(e) {
        if (e.which === 13) {
            $('#add_slave_button').click();
        }
    });
    
    // Test master connection button
    $('#test_master_connection').click(function() {
        window.location = 'skp:test_master_connection';
    });
    
    // Test all connections button
    $('#test_connections').click(function() {
        window.location = 'skp:test_all_connections';
    });
    
    // Start network render button
    $('#start_network_render').click(function() {
        window.location = 'skp:start_network_render';
        $('#render_status').text('Rendering...');
    });
    
    // Export only button
    $('#export_only').click(function() {
        window.location = 'skp:export_scene';
        $('#render_status').text('Exported');
    });
    
    // Text input handlers
    $('#network_luxcore_path_local').change(function() {
        window.location = 'skp:param_generate=network_luxcore_path_local=' + encodeURIComponent($(this).val());
    });
    
    $('#network_luxcore_path_network').change(function() {
        window.location = 'skp:param_generate=network_luxcore_path_network=' + encodeURIComponent($(this).val());
    });
    
    $('#network_master_address').change(function() {
        window.location = 'skp:param_generate=network_master_address=' + encodeURIComponent($(this).val());
    });
    
    $('#network_master_port').change(function() {
        window.location = 'skp:param_generate=network_master_port=' + $(this).val();
    });
    
    $('#network_output_path').change(function() {
        window.location = 'skp:param_generate=network_output_path=' + encodeURIComponent($(this).val());
    });
    
    $('#network_threads_per_node').change(function() {
        window.location = 'skp:param_generate=network_threads_per_node=' + $(this).val();
    });
    
    // Header expand/collapse
    $('p.header').click(function() {
        $(this).next('div.collapse').slideToggle(100);
    });
}

function update_render_mode_sections() {
    var enabled = $('#network_rendering_enabled').is(':checked');
    var mode = $('#network_render_mode').val();
    
    // Show/hide network enabled section
    if (enabled) {
        $('.network_enabled_section').show();
    } else {
        $('.network_enabled_section').hide();
    }
    
    // Show/hide network path section based on checkbox
    if ($('#network_use_network_path').is(':checked')) {
        $('.network_path_section').show();
    } else {
        $('.network_path_section').hide();
    }
    
    // Show/hide sections based on render mode
    if (!enabled || mode === 'local') {
        $('.master_section').hide();
        $('.slave_management_section').hide();
        $('.slave_mode_section').hide();
    } else if (mode === 'master') {
        $('.master_section').show();
        $('.slave_management_section').show();
        $('.slave_mode_section').hide();
    } else if (mode === 'slave') {
        $('.master_section').hide();
        $('.slave_management_section').hide();
        $('.slave_mode_section').show();
    }
}

function removeSlave(address) {
    window.location = 'skp:remove_slave_node=' + encodeURIComponent(address);
}

function updateStatus(status) {
    $('#render_status').text(status);
}
