require 'sketchup.rb'
require 'pathname'
require 'fileutils'

module BFJO
  module House

    def self.register
    	lic_file = UI.openpanel("打开license文件", "c:/", ".lic")
    	if lic_file == nil
        return false
      end
      dest_lic_path = "c:\/Users\/" + ENV['USERNAME'] + "\/AppData\/Roaming\/BFJO license\/"
      if lic_file =~ /(.*).lic/
      	#如果目录不存在，则创建目录
      	if !File.exist?(dest_lic_path) 
      		begin
              Dir.mkdir(dest_lic_path)
            rescue Exception => e
              UI.messagebox('请关闭打开的license文件夹或lic后再重试！')
            return 
          end    			  
      	end
        begin
          FileUtils.cp("#{lic_file}","#{dest_lic_path}")
          UI.messagebox('添加license成功！')
          rescue Exception => e
          puts e
        end    
        #UI.messagebox("")
  		else
  			UI.messagebox("没有发现测量仪license文件！")
      end
    end

    def self.scan_lic_file
      lic_path = "c:\/Users\/" + ENV['USERNAME'] + "\/AppData\/Roaming\/BFJO license\/"
      serials = ""
      if File.directory?(lic_path)
        pfile = lic_path + "*.lic"
        Dir.glob(pfile) do |filename|
          fname = File.basename(filename).split(".")
          if serials != ""
            serials = serials +","+ fname[0]
          else
            serials = fname[0]
          end
        end
      else
        #UI.messagebox("license文件不存在！")
      end
      return serials
    end

  end
end