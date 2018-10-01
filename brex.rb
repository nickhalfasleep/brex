#!/usr/bin/ruby
require 'cgi'
require 'sanitize'
require 'zip'

cgi = CGI.new
creator =        Sanitize.fragment(cgi['creator'], Sanitize::Config::RESTRICTED)
extension_name = Sanitize.fragment(cgi['name'], Sanitize::Config::RESTRICTED)
group =          Sanitize.fragment(cgi['group'], Sanitize::Config::RESTRICTED)
title =          Sanitize.fragment(cgi['title'], Sanitize::Config::RESTRICTED)
description =    Sanitize.fragment(cgi['description'], Sanitize::Config::RESTRICTED)
version =        Sanitize.fragment(cgi['version'], Sanitize::Config::RESTRICTED)
copyright =      Sanitize.fragment(cgi['copyright'], Sanitize::Config::RESTRICTED)
cmd1_name =      Sanitize.fragment(cgi['tool1_name'], Sanitize::Config::RESTRICTED)
cmd1_name_clean = cmd1_name

file_stream = Zip::OutputStream.write_buffer do |zip|

  # The loader script
  ext_load_string = <<-EXTLOADBODY
require 'sketchup.rb'
require 'extensions.rb'

module #{group_name}
module #{extension_name}
  unless file_loaded?(__FILE__)
	  # Leave the file suffix off the loader, in case this is encrypted
    ex = SketchupExtension.new('#{title}', #{extension_name}/#{extension_name}_main')
    ex.description = '#{description}'
    ex.version     = '#{version}'
    ex.copyright   = '#{creator} © 2018'
    ex.creator     = '#{creator}'
    Sketchup.register_extension(ex, true)
    file_loaded(__FILE__)
  end
end # module #{extension_name}
end # module #{group_name}
EXTLOADBODY

  zip.put_next_entry extension_name + '.rb'
  zip.print ext_load_string

  # The action script
  ext_action_script = <<-EXTACTIONBODY
# Copyright 2018 #{creator} 
# Licensed under #{license}

require 'sketchup.rb'

module #{group}
  module #{extension_name}

    def self.#{cmd1_name_clean}
      model = Sketchup.active_model
      model.start_operation('#{cmd1_name_clean}', true)
      
      # Insert your imagination here!
      UI.messagebox('Insert Your Imagination Here!')
      model.commit_operation
    end

    unless file_loaded?(__FILE__)
      main_menu = UI.menu('Extensions').add_submenu('#{title}')
      main_menu.add_item('#{cmd1_name}') {
        self.#{cmd1_name_clean}
      }
      file_loaded(__FILE__)
    end

  end # module #{extension_name}
end # module #{group}

EXTACTIONBODY

  zip.put_next_entry extension_name + '/' + extension_name + '_main.rb'
  zip.print ext_action_script
end
file_stream.rewind
binary_data = file_stream.string

myfilename = extension_name + '.rbz'
cgi.out( "Content-Type" => 'application/rbz',
  "Content-Disposition" => "attachment;filename=#{myfilename}") {
  binary_data
}

