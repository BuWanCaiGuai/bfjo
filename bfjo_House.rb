require 'sketchup.rb'
require 'extensions.rb'
module BFJO
	module House
	VERSION = "1.0.0"

    # Create an entry in the  "Extensions" list ("Preferences" dialog)
    #  that loads the main loader script, for this extension:

    @@extension = SketchupExtension.new(
      "BFJO: House",                           # The extension name
      "bfjo_House/House_loader.rb"  # The loader file path
    )

    @@extension.version = VERSION

    @@extension.creator = "BFJO"

    @@extension.copyright = "©2017, by BFJO, All Rights Reserved"
    
    @@extension.description = 'An extension for construct kitchen countertops with measure data.'
    
    # Register this extension with the Sketchup::ExtensionManager:
    Sketchup.register_extension(@@extension, true)

  end # this plugin sub-module
end # author's toplevel namespace module