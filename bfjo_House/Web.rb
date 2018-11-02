module BFJO
	module House
		class UIWeb < UI::WebDialog
			# @@canClick = 0
	      def initialize 
	        #插件源地址
	        @attribute = {}
	        @baseDir = File.dirname(__FILE__)
	        max_width = 560
	        max_height = 700
	        super "房间测量", false, "房屋测量", 400, 600, 100, 100, false
	        ui_loc = File.join(@baseDir , "ui.html")
	        ui_loc.gsub!('//', "/")
	        set_file(ui_loc)
	       	max_width = 560
	        max_height = 700
	        #设置大小width，height
	        set_size(max_width,max_height) 
	        # #设置位置left，top
	        left = 20
	        top = 80
	        set_position(left,top) 
	        # 展示webdialog
	        show
	      end
	        
	      def method_missing(name,*arg)
	        attribute = name.to_s
	        if attribute =~ /=$/
	          @attribute[attribute.chop] = arg[0]
	        else
	          @attribute[attribute]
	        end
	      end

	      # def canClick
	      # end
          def execute(params)
          	params = params.split(',')
          	function_name =params[0]	
          	length = params.length 
			if length==1
				House.send function_name
			elsif length>=2
				specific_params = params[1...length]
				#2个参数，不传递数组，直接传递元素
				if length==2
					House.send function_name,specific_params[0]	
				else
					House.send function_name,specific_params
				end
			end	
          end
	    end
	    #模块函数
	    def self.getCanClick(type)
	      #测量对象：如果当前工作为空，则可进行
	      if House.current_work == '' && type.to_i == 0
	      	 House.Web.canClick = 1
	      end
	      #得到按钮是否为可按
	      House.Web.execute_script("getCanClick_fromRuby("+House.Web.canClick.to_s+")")
    	end

    	def self.resetCanClick
      		House.Web.canClick = 0 
    	end


    	def self.get_serials
    		House.serials = self.scan_lic_file 
            state = "'"+"#{serials}"+"'"
            House.Web.execute_script("get_serials("+"#{state}"+")")
    	end
	end
end