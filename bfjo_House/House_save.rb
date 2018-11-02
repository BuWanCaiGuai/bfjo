module BFJO
  module House
    #保存打扮家方案
    # def self.save(file_name)
    #   if House.is_measure_end == 1
    #     House.Web.canClick = 1
    #     model = Sketchup.active_model
    #     save_path = "c:\/Users\/" + ENV['USERNAME'] + "\/Desktop\/测房"
    #     skp_save_path = "#{save_path}\/skp"
    #     dbj_save_path = "#{save_path}\/打扮家"
    #     my_data_file_save_path = "#{save_path}\/datafile"
    #     if !(File.directory? save_path)           
    #       begin
    #         Dir.mkdir(save_path)
    #         Dir.mkdir(skp_save_path)
    #         Dir.mkdir(dbj_save_path)
    #         Dir.mkdir(my_data_file_save_path)
    #       rescue Exception => e
    #         UI.messagebox('请关闭打开的测量数据文件夹或测量数据后再重试！')
    #         return
    #       end
    #     end
    #     time = Time.new
    #     date = time.strftime("%Y-%m-%d_%H-%M-%S").to_s
    #     house_attribute = ""
    #     puts House.house
    #     # House.house.get["house_name"].each{ |house_name|  
    #     #   house_attribute += house_name
    #     # }
    #     # file_name = house_attribute+'_'+"#{date}"
    #     dbj_file_name = file_name +".json"
    #     is_dbj_save_success = self.dbj_save(dbj_save_path+"\/"+dbj_file_name)

    #     skp_file_name = file_name +".skp"
    #     is_skp_save_success = model.save(skp_save_path+"\/"+skp_file_name) if skp_file_name
        
    #     mjson_file_name = file_name +".mjson"
    #     is_mjson_save_success =  self.data_file_save(my_data_file_save_path+"\/"+mjson_file_name)

    #     is_save_success = is_dbj_save_success && is_skp_save_success && is_mjson_save_success

    #     if is_save_success
    #       message = "'文件保存成功！'"
    #       House.Web.execute_script("hide_message()")
    #       House.Web.execute_script("showMessage("+"#{message}"+")")
    #     end
    #   else
    #     UI.messagebox("未创建房屋或测量尚未结束。")
    #   end
    # end

    #保存
    def self.save(type)

      if House.is_measure_end == 1
        House.Web.canClick = 1
        model = Sketchup.active_model
        save_path = "c:\/Users\/" + ENV['USERNAME'] + "\/Desktop\/测房"
        skp_save_path = "#{save_path}\/skp"
        dbj_save_path = "#{save_path}\/打扮家"
        my_data_file_save_path = "#{save_path}\/datafile"
        if !(File.directory? save_path)           
          begin
            Dir.mkdir(save_path)
            Dir.mkdir(skp_save_path)
            Dir.mkdir(dbj_save_path)
            Dir.mkdir(my_data_file_save_path)
          rescue Exception => e
            UI.messagebox('请关闭打开的测量数据文件夹或测量数据后再重试！')
            return
          end
        end
        time = Time.new
        date = time.strftime("%Y-%m-%d_%H-%M-%S").to_s
        house_attribute = ""
        # puts House.house
        if House.house == nil
          message="'请先创建房间！'"
          House.Web.execute_script("showMessage("+"#{message}"+")")
          return
        end
        House.house.get["house_name"].each{ |house_name|  
          house_attribute += house_name
        }
        file_name = house_attribute+'_'+"#{date}"
        is_save_success = 0

        if type == "dbj"
          s = file_name + ".json"
          filename = UI.savepanel("保存打扮家json文件", "#{dbj_save_path}", "#{s}")
          if filename != nil
            is_save_success = 1
            self.dbj_save(filename)

            skp_path = filename.to_s.split(".")[0]+".skp"
            status = model.save(skp_path) if filename
            msjon_path = filename.to_s.split(".")[0]+".mjson"
            self.data_file_save(msjon_path )
            House.Web.execute_script("hide_message()")        
          end
          
        elsif type == "skp"
          s = file_name + ".skp"
          filename = UI.savepanel("保存房屋", "#{skp_save_path}", "#{s}")
          if filename != nil
            is_save_success = 1
            House.Web.execute_script("hide_message()")    
          end
          status = model.save(filename) if filename

        elsif type == "datafile"
          s = file_name + ".mjson"
          filename = UI.savepanel("保存测量文件", "#{my_data_file_save_path}", "#{s}")
          if filename != nil
            is_save_success = 1
            self.data_file_save(filename)
            House.Web.execute_script("hide_message()")    
          end
        end
        if is_save_success == 1
          message = "'文件保存成功！'"
          House.Web.execute_script("showMessage("+"#{message}"+")")
        end
      else
        UI.messagebox("未创建房屋或测量尚未结束。")
      end
    end
    #存储单条测量记录
    def self.save_single_measure_record(record)
      House.measure_record.push(record)
    end
    #主要保存测量数据及测量过程
    #参数： measurement_process_record：测量过程记录
    def self.save_measure_data
      #保存测量过程为txt文件
      # puts 'bbb'
      if House.measure_record.length != 0
        #主程序文件路径
        #main_program_path = Pathname.new("#{File.dirname(__FILE__)}//").realpath
        #puts main_program_path
        #判断测量数据文件夹是否存在
        path = "c:\/Users\/" + ENV['USERNAME'] + "\/Desktop"
        measure_path = "#{path}/measure_data"
        
        if !(File.directory? measure_path)           
          begin
            Dir.mkdir(measure_path)
          rescue Exception => e
            UI.messagebox('请关闭打开的测量数据文件夹或测量数据后再重试！')
          return 
          end
        end

        time = Time.new
        date = time.strftime("%Y-%m-%d_%H-%M-%S").to_s
        house_attribute = ""
        House.house.get["house_name"].each{ |house_name|  
          house_attribute += house_name
        }
        current_measure_path = "#{measure_path}/#{house_attribute}#{House.room.get[0]}_" + date
        begin
            Dir.mkdir(current_measure_path)
          rescue Exception => e
            UI.messagebox('请关闭打开的测量数据文件夹或测量数据后再重试！')
          return 
        end
        #复制测量数据
        if House.filename != nil && House.filename != ""
          #测量数据源地址
          src = House.filename
          dest = current_measure_path
          #实现测量数据文件拷贝
          FileUtils.cp("#{src}","#{dest}")
          #找到最后一个文件分隔符的位置
          last_file_separator = nil
          str_length = src.length
          index = 0
          while index < str_length
            if src[index] == "\/" 
              last_file_separator = index
            end
            index+=1
          end
          measure_data_name = src[last_file_separator+1...str_length] 
          puts "#{measure_data_name}"
          measure_data_path = "#{current_measure_path}" +"//"+"#{measure_data_name}"
          puts measure_data_path
          #测量数据重命名
          File.rename("#{measure_data_path}","#{current_measure_path}//#{house_attribute}测量数据"+".dtpro" )  
        end
        measure_process_file = File.new("#{current_measure_path}//#{house_attribute}测量过程"+".txt", "w+")
        record = []
        record = House.measure_record
        record.each{|line|
          measure_process_file.puts(line)
        }
        measure_process_file.close
        state = "'[Save]保存测量数据成功！'"
        House.Web.execute_script("show("+"#{state}"+")")
        state = "'[Path]保存路径:'+'#{current_measure_path}'"
        House.Web.execute_script("show("+"#{state}"+")")
        message = "'保存测量数据成功！'"
        House.Web.execute_script("showMessage("+"#{message}"+")")
      end
    end

    def self.dbj_save(filepath)
      if filepath != nil
        json_path_name = filepath
        json_file = File.new(json_path_name,"w")
        json = self.to_dbj_json  
        json_file.puts json
        json_file.close
        return true
      else
        return false
      end
    end

    def self.to_dbj_json
      house_json = {}
      
      texts = House.house.get["house_name"]
      name_text = texts[0]+"小区"+texts[1]+"门栋"+texts[2]+"房"
      house_json["name"] = name_text

      rooms = [] # "rooms"->rooms

      House.house.get["rooms"].each{ |roomname,room|
        room_json = {} #
        room_json["roomname"] = "#{room.get["id"]}"
        room_json["homeheight"] = "#{room.get["height"]}"

        walls = room.get["mobjects"]["BFJO::House::Wall"] #房间中所有墙，包含门
        door_set = room.get["mobjects"]["BFJO::House::Door"]
        window_set = room.get["mobjects"]["BFJO::House::Window"] #房间中所有窗
        columns = room.get["mobjects"]["BFJO::House::Column"]
        girders = room.get["mobjects"]["BFJO::House::Girder"]
        electricities = room.get["mobjects"]["BFJO::House::Electricity"]
        skirtingline = room.get["mobjects"]["BFJO::House::Skirtingline"]
        
        windows = []
        doors = []
        pillars = []
        beams = []
        skirtingline_array = []
        points_json = []
        point_hash = {} # "wall_id" -> points_json 用于将points_json = [] 加入到json中的点        

        if walls != []
          
          i = 0
          walls.each{ |wall|

            wall_id = wall.get["id"].reverse.to_i #获得墙的id作为point_hash的key
            puts "#{wall_id}"
            point_hash["#{wall_id}"] = []
            point = [wall.get["inner_points"][0].x,wall.get["inner_points"][0].y,wall.get["inner_points"][0].z]
            point.z = 0
            point_hash["#{wall_id}"].push(point)
            #line暂时不实现
            i = i + 1
          }
        end

        #墙的每个门
        if door_set != [] && door_set != nil
          room.get["mobjects"]["BFJO::House::Door"].each{ |door|
            wall = walls[door.get["wid"].to_i - 1]
            point1 = [door.get["points"][0].x,door.get["points"][0].y,door.get["points"][0].z]
            point2 = [door.get["points"][1].x,door.get["points"][1].y,door.get["points"][1].z]
            door_point = {}
            if point1.z > point2.z
              ground_clearance = point2.z
              height = point1.z - point2.z
            else
              ground_clearance = point1.z
              height = point2.z - point1.z
            end
            point3 = point2
            point3.z = point1.z
            width = point3.distance(point1)
            vec = wall.get["normal_vector"]
            vec.length = wall.get["thickness"] / 2
            tr = Geom::Transformation.translation(vec)
            point3 = point1.transform tr
            point4 = point2.transform tr
            # House.entities.add_cpoint point3
            # House.entities.add_cpoint point4
            door_point["Center1_X"] = "#{point3.x.to_mm.round}"
            door_point["Center1_Y"] = "#{point3.y.to_mm.round}"
            door_point["Center2_X"] = "#{point4.x.to_mm.round}"
            door_point["Center2_Y"] = "#{point4.y.to_mm.round}"
            door_point["width"] = "#{width.to_mm.round}"
            door_point["height"] = "#{height.to_mm.round}"
            door_point["depth"] = "#{wall.get["thickness"].to_mm.round}"
            door_point["ground_clearance"] = "#{ground_clearance.to_mm.round}"
            door_point["rotate"] = "0"
            door_point["door_Type"] = "1"
            doors.push(door_point)

            point1.z = 0
            point2.z = 0
            wall_id = door.get["wid"]
            point_hash["#{wall_id}"].push(point1)
            point_hash["#{wall_id}"].push(point2)
          }
        end

        if window_set != [] && window_set != nil
          window_set.each{ |window|
            if window.get["type"] != "L_bay_window" 
              #如果不是转角飘窗和U型飘窗

              #  普通窗 normal_window                        
              #           *—— —— —— —— —— —— —— *  
              #           |                     |
              #  center1  *—— —— —— —— —— —— —— * center2
              #           |                     |
              #  points[0]*—— —— —— —— —— —— —— * points[1]
              #  
              #  一字飘窗 bay_window
              #  points[2]*—— —— —— —— —— —— —— * 
              #           |                     |
              #  center1  *—— —— —— —— —— —— —— * center2
              #           |                     |
              #  points[0]*—— —— —— —— —— —— —— * points[1]
              #                            

              #则获取窗对角两点
              point1 = [window.get["points"][0].x,window.get["points"][0].y,window.get["points"][0].z]
              point2 = [window.get["points"][1].x,window.get["points"][1].y,window.get["points"][1].z]
              window_point = {}

              wall_id = window.get["wid"].to_i
              wall = walls[wall_id - 1] #获取窗所依附的墙

              if window.get["type"] == "normal_window"
                depth = wall.get["thickness"]
                window_Type = 0
              elsif window.get["type"] == "bay_window"
                point = wall.get["inner_points"][0] 
                vector = wall.get["normal_vector"]
                plane = [point,vector]
                depth = window.get["points"][2].distance_to_plane plane
                window_Type = 1
              end
              if point1.z > point2.z
                ground_clearance = point2.z
                height = point1.z - point2.z
              else
                ground_clearance = point1.z
                height = point2.z - point1.z
              end
              #计算窗的宽度
              point3 = [point2.x,point2.y,point2.z]
              point3.z = point1.z
              width = point3.distance(point1)

              #计算窗沿中心点
              vec = wall.get["normal_vector"]
              vec.length = depth / 2
              tr = Geom::Transformation.translation(vec)
              point3 = point1.transform tr
              point4 = point2.transform tr
              # House.entities.add_cpoint point3
              # House.entities.add_cpoint point4
              window_point["Center1_X"] = "#{point3.x.to_mm.round}"
              window_point["Center1_Y"] = "#{point3.y.to_mm.round}"
              window_point["Center2_X"] = "#{point4.x.to_mm.round}"
              window_point["Center2_Y"] = "#{point4.y.to_mm.round}"
              window_point["width"] = "#{width.to_mm.round}"
              window_point["height"] = "#{height.to_mm.round}"
              window_point["depth"] = "#{depth.to_mm.round}"
              window_point["ground_clearance"] = "#{ground_clearance.to_mm.round}"
              window_point["rotate"] = "0"
              window_point["window_Type"] = "#{window_Type}"
              windows.push(window_point)
              
              point1.z = 0
              point2.z = 0

              point_hash["#{wall_id}"].push(point1)
              point_hash["#{wall_id}"].push(point2)

            elsif window.get["type"] == "L_bay_window" #增加L飘窗的转换 xuyang20180330

              window_Type = 2

              #                           center2_1
              #  point1/3  *—— —— —— —— —— ———*——* point4
              #            |                     |
              #  center1_1 *                     * center1_2
              #            |                     |
              #  point3_   *—— —— —— —— —— *     |
              #                     point5 |     |
              #                            |     |
              #                    point2_ *——*——* point2
              #                            center2_2

              #point1为外轮廓左上角点，point2为外轮廓右下角点，point3为外轮廓左下角点，point4为L型飘窗外轮廓交点
              point1 = window.get["points"][0]
              point2 = window.get["points"][1]
              point3 = window.get["points"][2]
              point4 = window.get["points"][3]

              #找到匹配的墙
              walls_id = window.get["wid"].split(",")
              wall1 = walls[walls_id[0].to_i - 1]
              wall2 = walls[walls_id[1].to_i - 1]
              window_point = {}
              #求离地高clearance
              if point1.z > point3.z
                ground_clearance = point3.z
                height = point1.z - point3.z
              else
                ground_clearance = point1.z
                height = point3.z - point1.z
              end

              #获得point1、point3对应墙
              point_wall1 = wall1.get["inner_points"][0] #获得内墙点的第一个点
              vector1 = wall1.get["normal_vector"]
              plane1 = [point_wall1,vector1] #内墙面
              #获得point2对应墙
              point_wall2 = wall2.get["inner_points"][0] 
              vector2 = wall2.get["normal_vector"]
              plane2 = [point_wall2,vector2]
              #求point1对应窗深度depth1
              depth1 = point3.distance_to_plane plane1
              #求point2对应右窗深度depth2
              depth2 = point2.distance_to_plane plane2

              #求point3\point2到对应墙的投影点
              point3_ = point3.project_to_plane plane1
              point2_ = point2.project_to_plane plane2

              #求point3 point3_的中点center1_1
              center1_1 = Geometry::midpoint_between_2point(point3,point3_)
              #求point2 point2_的中点center2_2
              center2_2 = Geometry::midpoint_between_2point(point2,point2_)

              #求center1_2
              center3_p = Geometry::foot_point_to_line(point2,point4,point3_)#point3_至point2 point4的垂足
              center3_p.z = point2.z
              center1_2 = Geometry::midpoint_between_2point(point4,center3_p)

              #求center2-1
              center2_p = Geometry::foot_point_to_line(point3,point4,point2_)#point2_至point3 point4的垂足
              center2_p.z = point2.z
              center2_1 = Geometry::midpoint_between_2point(point4,center2_p)

              #打扮家点
              window_point["Center1_1X"] = "#{center1_1.x.to_mm.round}"
              window_point["Center1_1Y"] = "#{center1_1.y.to_mm.round}"
              window_point["Center1_2X"] = "#{center1_2.x.to_mm.round}"
              window_point["Center1_2Y"] = "#{center1_2.y.to_mm.round}"
              window_point["Center2_1X"] = "#{center2_1.x.to_mm.round}"
              window_point["Center2_1Y"] = "#{center2_1.y.to_mm.round}"
              window_point["Center2_2X"] = "#{center2_2.x.to_mm.round}"
              window_point["Center2_2Y"] = "#{center2_2.y.to_mm.round}"

              window_point["height"] = "#{height.to_mm.round}"
              window_point["depth1"] = "#{depth1.to_mm.round}"
              window_point["depth2"] = "#{depth2.to_mm.round}"
              window_point["ground_clearance"] = "#{ground_clearance.to_mm.round}"
              window_point["rotate"] = "0"
              window_point["window_Type"] = "#{window_Type}"
              windows.push(window_point)
              
              #防止误差z轴导致两直线异面
              
              point3_.z = 0 
              point_hash["#{walls_id[0].to_i}"].push(point3_)
              point2_.z = 0
              point_hash["#{walls_id[1].to_i}"].push(point2_)
              
            end
          }         
        end

        if point_hash != nil
          point_hash.each{ |key,point_array|
            i = 0
            point_array.each{ |a| #每面墙的dbj点顺时针排序
              m = a.distance(point_array[0])
              j = i
              for j in i..(point_array.size - 1)
                d = point_array[j].distance(point_array[0])
                if d < m
                  temp = point_array[i]
                  point_array[i] = point_array[j]
                  point_array[j] = temp
                  m = d
                end
                j += 1
              end
              i += 1
            }        
          }
          # 排序后的点转换为json

          hsize = point_hash.size
          for i in 1..hsize
            psize = point_hash["#{i}"].size
            for j in 0..(psize-1)
              point_json = {}
              point_json["X"] = "#{point_hash["#{i}"][j].x.to_mm.round}"
              point_json["Y"] = "#{point_hash["#{i}"][j].y.to_mm.round}"
              points_json.push(point_json)              
            end
          end 
        end

        if points_json != []
          room_json["points"] = points_json
        end

        if skirtingline != [] && skirtingline != nil
          skirtingline_hash = {}
          skirtingline_hash["skirtingline"] = "1"
          skirtingline_hash["url"] = "http://XXXXXX"
          skirtingline_hash["depth"] = "#{skirtingline[0].get["depth"].to_mm.round}"
          skirtingline_hash["height"] = "#{skirtingline[0].get["height"].to_mm.round}"
          skirtingline_array.push(skirtingline_hash)
          room_json["skirtingline"] = skirtingline_array
        else
          skirtingline_hash = {}
          skirtingline_hash["skirtingline"] = "0"
          skirtingline_hash["url"] = "http://XXXXXX"
          skirtingline_hash["depth"] = "0"
          skirtingline_hash["height"] = "0"
          skirtingline_array.push(skirtingline_hash)
          room_json["skirtingline"] = skirtingline_array
        end

        if doors != []
          room_json["doors"] = doors
        end

        if windows != []
          room_json["windows"] = windows
        end

        if columns != [] && columns != nil
          columns.each{ |column|
            cp1 = column.get["points"][0]
            cp2 = column.get["points"][1]
            cp3 = column.get["points"][2]
            mid = [(cp1.x + cp3.x) / 2,(cp1.y + cp3.y) / 2,0]
            width = cp3.distance(cp2)
            depth = cp1.distance(cp2)
            pillar = {}
            pillar["Center_X"] = "#{mid.x.to_mm.round}"
            pillar["Center_Y"] = "#{mid.y.to_mm.round}"
            pillar["width"] = "#{width.to_mm.round}"
            pillar["depth"] = "#{depth.to_mm.round}"
            pillars.push(pillar)
          }
          room_json["pillars"] = pillars
        end

        if girders != [] && girders != nil
          girders.each{ |girder|  
            gp1 = girder.get["points"][0]
            gp2 = girder.get["points"][1]
            gp3 = girder.get["points"][2]
            gp4 = girder.get["points"][3]
            gp5 = girder.get["points"][4]
            gp6 = girder.get["points"][5]
            gp7 = girder.get["points"][6]
            gp8 = girder.get["points"][7]
            mid1 = Geometry::intersect_between_lines(gp1,gp3,gp2,gp4)
            mid2 = Geometry::intersect_between_lines(gp5,gp7,gp6,gp8)
            ceiling = [walls[0].get["inner_points"][2],room.get["ceiling_vector"]]
            under_top = mid1.distance_to_plane(ceiling) + mid2.distance_to_plane(ceiling)
            width = gp1.distance(gp2)
            beam = {}
            beam["Center1_X"] = "#{mid1.x.to_mm.round}"
            beam["Center1_Y"] = "#{mid1.y.to_mm.round}"
            beam["Center2_X"] = "#{mid2.x.to_mm.round}"
            beam["Center2_Y"] = "#{mid2.y.to_mm.round}"
            beam["width"] = "#{width.to_mm.round}"
            beam["Under_Top"] = "#{under_top.to_mm.round}"
            beams.push(beam)
          }
          room_json["beams"] = beams
        end

        if electricities != [] && electricities != nil
          electricities.each{ |electricity|  
            if electricity.get["type"][0] == 1
              a = {}
              x = electricity.get["points"][0].x
              y = electricity.get["points"][0].y
              z = electricity.get["points"][0].z
              normal = electricity.get["normal"]
              if Geom::Vector3d.new(0,1,0).angle_between(normal) < 0.01
                normal = [0,1,0]
              elsif Geom::Vector3d.new(0,-1,0).angle_between(normal) < 0.01
                normal = [0,-1,0]
              elsif Geom::Vector3d.new(1,0,0).angle_between(normal) < 0.01
                normal = [1,0,0]
              elsif Geom::Vector3d.new(-1,0,0).angle_between(normal) < 0.01
                normal = [-1,0,0]
              end
              a["Center1_X"] = "#{x.to_mm.round}"
              a["Center1_Y"] = "#{y.to_mm.round}"
              a["Normal_X"] = "#{normal.x}"
              a["Normal_Y"] = "#{normal.y}"
              a["ground_clearance"] = "#{z.to_mm.round}"
              a["#{electricity.get["type"][1]}_Type"] = "1"
              if room_json["#{electricity.get["type"][1]}"] == nil
                room_json["#{electricity.get["type"][1]}"] = []
                room_json["#{electricity.get["type"][1]}"].push(a)
              else
                room_json["#{electricity.get["type"][1]}"].push(a)
              end
            elsif electricity.get["type"][0] == 2
              
            end
          }
        end
        rooms.push(room_json)
      }
      house_json["rooms"] = rooms
      return JSON.generate(house_json)
      # }
    end

    def self.data_file_save(filepath)
      if filepath != nil
        json_path_name = filepath
        json_file = File.new(json_path_name,"w")
        json = self.my_data_file
        json_file.puts json
        json_file.close
        return true
      else
        return false
      end
    end

    def self.my_data_file
      house_json = {}
      house_json["version"] = "2.0.0"
      house_json["house_name"] = House.house.get["house_name"]
      rooms = []
      House.house.get["rooms"].each{ |roomname,room| 
        
        walls = room.get["mobjects"]["BFJO::House::Wall"]
        columns = room.get["mobjects"]["BFJO::House::Column"]
        girders = room.get["mobjects"]["BFJO::House::Girder"]
        electricities = room.get["mobjects"]["BFJO::House::Electricity"]
        skirtingline = room.get["mobjects"]["BFJO::House::Skirtingline"]
        tripoint_pipes = room.get["mobjects"]["BFJO::House::Tripoint_pipe"]
        water_pipes = room.get["mobjects"]["BFJO::House::Water_pipe"]
        windows = room.get["mobjects"]["BFJO::House::Window"]
        doors = room.get["mobjects"]["BFJO::House::Door"]
        ceilingline = room.get["mobjects"]["BFJO::House::Ceilingline"]
        steps = room.get["mobjects"]["BFJO::House::Steps"]
        suspended_ceilings = room.get["mobjects"]["BFJO::House::Suspended_ceiling"]

        json_hash = {}
        cwalls = []
        cdoors = []
        cwindows = []
        walls_array = []
        celectricities = []
        pillars = []
        beams = []
        csteps = []
        tripoint_pipes_array = []
        water_pipes_array = []
        csuspended_ceilings = []

        json_hash["room_name"] = "#{room.get["id"]}"
        json_hash["room_height"] = room.get["height"]

        if room.get["floor_vector"] != nil
          json_hash["floor_vector"] = [room.get["floor_vector"].x.to_mm,room.get["floor_vector"].y.to_mm,room.get["floor_vector"].z.to_mm]
        end

        if room.get["ceiling_vector"] != nil
          json_hash["ceiling_vector"] = [room.get["ceiling_vector"].x.to_mm,room.get["ceiling_vector"].y.to_mm,room.get["ceiling_vector"].z.to_mm]
        end

        if walls != []
          walls.each{ |wall|
            cwall = {}
            cwall["wall_id"] = wall.get["id"]
            cwall["wall_thickness"] = wall.get["thickness"].to_mm
            normal_vector = wall.get["normal_vector"]
            cwall["normal_vector"] = [normal_vector.x.to_mm,normal_vector.y.to_mm,normal_vector.z.to_mm]
            inner_points = []
            wall.get["inner_points"].each{ |point|
              inner_point = [point.x.to_mm,point.y.to_mm,point.z.to_mm]
              inner_points.push(inner_point)
            }
            cwall["inner_points"] = inner_points
            outter_points = []
            wall.get["outter_points"].each{ |point|
              outter_point = [point.x.to_mm,point.y.to_mm,point.z.to_mm]
              outter_points.push(outter_point)
            }
            cwall["outter_points"] = outter_points
            walls_array.push(cwall)
          }
          json_hash["walls"] = walls_array
        end

        if doors != [] && doors != nil
          doors.each{ |door|
            cdoor = {}
            door_points = []
            cdoor["id"] = door.get["id"]
            cdoor["wid"] = door.get["wid"]
            door.get["points"].each{ |point|
              door_point = [point.x.to_mm,point.y.to_mm,point.z.to_mm]
              door_points.push(door_point)
            }
            cdoor["door_points"] = door_points
            cdoors.push(cdoor)
          }
          json_hash["doors"] = cdoors
        end

        if windows != [] && windows != nil
          windows.each{ |window|
            cwindow = {}
            window_points = []
            cwindow["id"] = window.get["id"]
            cwindow["wid"] = window.get["wid"]
            window.get["points"].each{ |point|  
              window_point = [point.x.to_mm,point.y.to_mm,point.z.to_mm]
              window_points.push(window_point)
            }
            cwindow["window_points"] = window_points
            cwindow["window_type"] = window.get["type"]
            cwindows.push(cwindow)
          }
          json_hash["windows"] = cwindows
        end

        if columns != [] && columns != nil
          columns.each{ |column|
            pillar = {}
            pillar_points = []
            pillar["id"] = column.get["id"]
            pillar["type"] = column.get["type"]
            column.get["points"].each{ |point|  
              pillar_point = [point.x.to_mm,point.y.to_mm,point.z.to_mm]
              pillar_points.push(pillar_point)
            }
            pillar["column_points"] = pillar_points
            pillars.push(pillar)
          }
          json_hash["columns"] = pillars
        end
        
        if girders != [] && girders != nil
          girders.each{ |girder|
            beam = {}
            beam_points = []
            beam["id"] = girder.get["id"]
            beam["type"] = girder.get["type"]
            girder.get["points"].each{ |point|  
              beam_point = [point.x.to_mm,point.y.to_mm,point.z.to_mm]
              beam_points.push(beam_point)
            }
            beam["girder_points"] = beam_points
            beams.push(beam)
          }
          json_hash["girders"] = beams
        end

        if steps != [] && steps != nil
          steps.each{ |step|  
            cstep = {}
            step_points = []
            cstep["id"] = step.get["id"]
            step.get["points"].each{ |point|  
              step_point = [point.x.to_mm,point.y.to_mm,point.z.to_mm]
              step_points.push(step_point)
            }
            cstep["steps_points"] = step_points
            csteps.push(cstep)
          }
          json_hash["steps"] = csteps
        end
        
        if electricities != [] && electricities != nil
          electricities.each{ |electricity|  
            celectricity = {}
            celectricity["id"] = electricity.get["id"]
            celectricity["num"] = electricity.get["num"]
            if electricity.get["tag"] != nil
              celectricity["tag"] = electricity.get["tag"]
            end
            celectricity["electricity_type"] = [electricity.get["type"][0],electricity.get["type"][1]]
            electricity_normal = electricity.get["normal"]
            celectricity["electricity_vector"] = [electricity_normal.x.to_mm,electricity_normal.y.to_mm,electricity_normal.z.to_mm]
            if electricity.get["type"][0] == 2
              edge_vector = electricity.get["edge_vector"]
              celectricity["electricity_edge_vector"] = [edge_vector.x.to_mm,edge_vector.y.to_mm,edge_vector.z.to_mm]
            end
            electricity_points = []
            electricity.get["points"].each{ |point|  
              electricity_point = [point.x.to_mm,point.y.to_mm,point.z.to_mm]
              electricity_points.push(electricity_point)
            }
            celectricity["electricity_points"] = electricity_points
            celectricities.push(celectricity)
          }
          json_hash["electricities"] = celectricities
        end

        if skirtingline != [] && skirtingline != nil
          skirtingline_hash = {}
          skirtingline_hash["id"] = skirtingline[0].get["id"]
          skirtingline_hash["skirtingline_height"] = skirtingline[0].get["height"].to_mm
          skirtingline_hash["skirtingline_depth"] = skirtingline[0].get["depth"].to_mm
          json_hash["skirtingline"] = skirtingline_hash
        end

        if ceilingline != [] && ceilingline != nil
          ceilingline_hash = {}
          ceilingline_hash["id"] = ceilingline[0].get["id"]
          ceilingline_hash["ceilingline_height"] = ceilingline[0].get["height"]
          ceilingline_hash["ceilingline_depth"] = ceilingline[0].get["depth"].to_mm
          json_hash["ceilingline"] = ceilingline_hash
        end

        if tripoint_pipes != [] && tripoint_pipes != nil
          tripoint_pipes.each{ |tripoint_pipe|  
            tripoint_pipe_hash = {}
            tripoint_pipe_hash["id"] = tripoint_pipe.get["id"]
            center = tripoint_pipe.get["points"][0]
            center = [center.x.to_mm,center.y.to_mm,center.z.to_mm]
            tripoint_pipe_hash["center"] = center
            tripoint_pipe_hash["radius"] = tripoint_pipe.get["radius"].to_mm
            tripoint_pipe_hash["height"] = tripoint_pipe.get["height"].to_mm
            tripoint_pipes_array.push(tripoint_pipe_hash)
          }
          json_hash["tripoint_pipes"] = tripoint_pipes_array
        end

        if water_pipes != [] && water_pipes != nil
          water_pipes.each{ |water_pipe|  
            water_pipe_hash = {}
            water_pipe_hash["id"] = water_pipe.get["id"]
            center = water_pipe.get["points"][0]
            center = [center.x.to_mm,center.y.to_mm,center.z.to_mm]
            vector = water_pipe.get["normal"]
            vector = [vector.x.to_mm,vector.y.to_mm,vector.z.to_mm]
            water_pipe_hash["center"] = center
            water_pipe_hash["normal"] = vector
            water_pipe_hash["radius"] = water_pipe.get["radius"].to_mm
            water_pipe_hash["height"] = water_pipe.get["height"].to_mm
            water_pipe_hash["type"] = water_pipe.get["type"]
            water_pipes_array.push(water_pipe_hash)
          }
          json_hash["water_pipes"] = water_pipes_array
        end

        if suspended_ceilings != [] && suspended_ceilings != nil
          suspended_ceilings.each{ |suspended_ceiling|  
            suspended_ceiling_hash = {}
            suspended_ceiling_points = []
            suspended_ceiling.get["points"].each{ |point|  
              suspended_ceiling_point = [point.x.to_mm,point.y.to_mm,point.z.to_mm]
              suspended_ceiling_points.push(suspended_ceiling_point)
            }
            suspended_ceiling_hash["suspended_ceiling_points"] = suspended_ceiling_points
            csuspended_ceilings.push(suspended_ceiling_hash)
          }
          json_hash["suspended_ceilings"] = csuspended_ceilings
        end
        rooms.push(json_hash)
        # puts json_hash
        # puts rooms
      }
      house_json["rooms"] = rooms
      return JSON.generate(house_json)
    end
  end
end