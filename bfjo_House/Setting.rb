module BFJO
  module House
    def self.get_measure_count
      file = File.open("#{File.dirname(__FILE__)}\/setting\/measure_count",'r') 
      House.measure_count = {}
      while line = file.gets   #标准输入流
        line.chop!
        line = line.split(",")
        #如果测量对象对应哈希值为空则需要将measure_to_count清空
        if House.measure_count["#{line[0]}"] == nil 
          measure_to_count = {}
        end
        measure_to_count["#{line[1]}"] = line[2]
        House.measure_count["#{line[0]}"] = measure_to_count
        #puts text_hash
      end
      file.close
    end

    def self.get_electricity_map
      file = File.open("#{File.dirname(__FILE__)}\/setting\/measure_count",'r') 
      House.electricity_map_hash = {}
      while line = file.gets   #标准输入流
        line.chop!
        line = line.split(",")
        if line[0] == "electricity"
          House.electricity_map_hash[line[1]] = line[3]
        end
      end
      file.close
    end
    #set_conut用于确定当前测量对象和测量方式
    def self.set_count(measure_parameters)
      c_work = measure_parameters[0]
      c_method = measure_parameters[1]
      if c_work == "skirtingline"
        UI.messagebox("测量踢脚线之前，请务必先完成房间内所有门的测量！")
      end
      House.current_work = c_work
      if c_method != nil
        House.measure_option = c_method.to_i
        House.count = House.measure_count[c_work][c_method].to_i
        House.last_count = House.count
        House.Web.execute_script("set_endMeasure_btn_visible("+"#{House.count}"+")")
      else
        UI.messagebox("设置count出错")
      end
    end

    def self.get_measure_name_map
      file = File.open("#{File.dirname(__FILE__)}\/setting\/measure_name_map",'r') 
      House.measure_name_map = {}
      while line = file.gets   #标准输入流
        line.chop!
        line = line.split(",")
        House.measure_name_map[line[0]] = line[1]
      end
      file.close
    end

    def self.receive_door_tag
      file = File.open("#{File.dirname(__FILE__)}\/setting\/door_tag",'r') 
      text_array = []
      while line = file.gets   #标准输入流
        line.chop!
        text_array.push(line)
      end
      file.close
      # UI.messagebox("#{text_array}")
      return text_array
    end

    def self.receive_room_tag
      file = File.open("#{File.dirname(__FILE__)}\/setting\/room_tag",'r') 
      text_array = []
      while line = file.gets   #标准输入流
        line.chop!
        text_array.push(line)
      end
      file.close
      # UI.messagebox("#{text_array}")
      return text_array
    end

    def self.add_room_tag(room_type)
          file = File.open("#{File.dirname(__FILE__)}\/setting\/room_tag",'a') 
          file.puts(room_type)
          file.close()
        end

    def self.add_door_tag(door_type)
          file = File.open("#{File.dirname(__FILE__)}\/setting\/door_tag",'a') 
          file.puts(door_type)
          file.close()
        end
        
    def self.update_room_tag_file(room_type_array)
        begin
          House.Web.canClick = 0
          file = File.open("#{File.dirname(__FILE__)}\/setting\/room_tag",'w+')
          #判断是否是数组
          if room_type_array.is_a? Array
            room_type_array.each{|room_tag|
            file.puts(room_tag)
          }
          else
            file.puts(room_type_array)
          end
          
          file.close()
          House.Web.canClick = 1
        rescue Exception => e
          House.Web.canClick = 0
          puts e
        end
  end      
   def self.delete_room_tag(door_type)
            file = File.open("#{File.dirname(__FILE__)}\/setting\/room_tag",'w+') 
            file.puts(door_type)
            file.close()
          end

   def self.delete_door_tag(door_type)
            file = File.open("#{File.dirname(__FILE__)}\/setting\/door_tag",'w+') 
            file.puts(door_type)
            file.close()
          end

    def self.update_room_tag
            room_tag_text_array = []
            room_tag_text_array = self.receive_room_tag
            House.Web.execute_script("set_select_room_tag("+"#{room_tag_text_array}"+")")
          end

    def self.update_door_tag
            door_tag_text_array = []#2018129
            door_tag_text_array = self.receive_door_tag#2018129
            House.Web.execute_script("set_select_door_tag("+"#{door_tag_text_array}"+")") #2018129
          end

    def self.update_color(rgb_array)
            color_array = []
            color_array = self.get_rgb
            case rgb_array[0]
            when "plane"
              puts (rgb_array[0])
              color_array[1] = rgb_array[1] 
              color_array[2] = rgb_array[2]
              color_array[3] = rgb_array[3]
            when "floor"
              puts (rgb_array[0])
              color_array[5] = rgb_array[1] 
              color_array[6] = rgb_array[2]
              color_array[7] = rgb_array[3]
            when "innerwall"
              puts (rgb_array[0])
              color_array[9] = rgb_array[1] 
              color_array[10] = rgb_array[2]
              color_array[11] = rgb_array[3]
            when "outterwall"
              puts (rgb_array[0])
              color_array[13] = rgb_array[1] 
              color_array[14] = rgb_array[2]
              color_array[15] = rgb_array[3]
            when "girder"
              puts (rgb_array[0])
              color_array[17] = rgb_array[1] 
              color_array[18] = rgb_array[2]
              color_array[19] = rgb_array[3]
            when "column"
              puts (rgb_array[0])
              color_array[21] = rgb_array[1] 
              color_array[22] = rgb_array[2]
              color_array[23] = rgb_array[3]
            when "ceilingline"
              puts (rgb_array[0])
              color_array[25] = rgb_array[1] 
              color_array[26] = rgb_array[2]
              color_array[27] = rgb_array[3]
            when "skirtingline"
              puts (rgb_array[0])
              color_array[29] = rgb_array[1] 
              color_array[30] = rgb_array[2]
              color_array[31] = rgb_array[3]
            end

            file = File.open("#{File.dirname(__FILE__)}\/setting\/rgb",'w+') 
            file.puts(color_array)
            file.close()
          end

    def self.get_rgb()
      file = File.open("#{File.dirname(__FILE__)}\/setting\/rgb",'r') 
      color_array = []
            while line = file.gets   #标准输入流
               line.chop!
               color_array.push(line)
            end
      return color_array


      end   

    def self.set_html_tag
      #读配置文件初始化
      room_tag_text_array = []#2018129
      room_tag_text_array = self.receive_room_tag#2018129
      House.Web.execute_script("set_select_room_tag("+"#{room_tag_text_array}"+")") #2018129

      House.Web.execute_script("set_room_tag("+"#{room_tag_text_array}"+")") #2018129
      door_tag_text_array = []#2018129
      door_tag_text_array = self.receive_door_tag#2018129
      House.Web.execute_script("set_door_tag("+"#{door_tag_text_array}"+")") #2018129
      House.Web.execute_script("set_select_door_tag("+"#{door_tag_text_array}"+")") #2018129
    end
  end
end