require 'sketchup.rb'
require 'json'
require 'pathname'
require 'fileutils'
require 'Win32api'

module BFJO
  module House
    include Geometry
    class << self
      #在此声明对Sketchup的设置相关变量
      attr_accessor :last_camera  
      attr_accessor :model
      attr_accessor :entities
      attr_accessor :last_entity
      attr_accessor :entity_group  #记录所有绘制元素的entity，在结束测量将所有entity添加进一个group时使用
      attr_accessor :room_observer  
      attr_accessor :room_deleted_observer   
      
      #在此声明测量控制变量(与测量实体无关的)
      attr_accessor :filename #记录文件名
      attr_accessor :is_measure_pause #用于暂停测量  0：表示继续测量 1：表示暂停
      attr_accessor :is_measure_end #用于控制测量是否结束 0：表示未结束 1：表示已结束，初始默认为1
      attr_accessor :current_work #记录当前测量工作，同时控制接收数据用于哪个测量
      
      attr_accessor :cpoints #记录读入的数据点
      attr_accessor :count
      attr_accessor :has_dimensioned

      attr_accessor :last_measure  #记录最后一次的测量对象
      attr_accessor :last_count #记录最后一次测量对象的测量点计数
      # attr_accessor :last_measure_method  #记录最后一次测量的测量方式

      attr_accessor :measure_count  #用于不同测量方式对应的count值
      attr_accessor :measure_option #确定测量方式

      attr_accessor :can_undo  #判断是否可以回退
      attr_accessor :undo_entity_observer
      attr_accessor :set_origin_tool_observer #设置绘制原点

      #在此声明交互用变量
      attr_accessor :Web
      attr_accessor :canClick #按钮是否可执行
      attr_accessor :page_opened_flag #防止页面重复打开
      attr_accessor :measure_record
      
      #以下为测量对象相关的变量
      attr_accessor :axes_tr  #记录坐标轴转换用的tr
      attr_accessor :origin_tr  #用于原点坐标转换的tr
      attr_accessor :room_tr
      attr_accessor :origin

      attr_accessor :house #存放当前house实例  新建house时初始化
      attr_accessor :room #记录当前room实例
      attr_accessor :wall_id #记录墙编号 
      
      attr_accessor :room_height
      attr_accessor :wall_thickness #记录墙厚度
      attr_accessor :mpoints  #记录绘制墙面时 ####

      attr_accessor :last_door  #记录最后测量的门的实例，在添加门标签时使用

      attr_accessor :water_pipe_radius  #接收页面传来的水管半径，用于绘制水管和绘制标签
            
      attr_accessor :electricity_map_hash  #记录electricity编号与名称之间的映射
      attr_accessor :measure_name_map #测量对象名称映射

      attr_accessor :current_floor #记录当前地板平面
      attr_accessor :current_ceiling #记录当前天花板平面

      attr_accessor :has_transformed
      #用于墙聚焦
      attr_accessor :wallFace_selObserver
      attr_accessor :cwall #当前墙
      attr_accessor :has_measured_focusedWall

      #序列号
      attr_accessor :serials
    end
    #插件加载时初始化
    House.page_opened_flag = 0
    House.measure_record = []
    House.model = Sketchup.active_model
    House.entities = House.model.entities
    House.last_camera = Sketchup::Camera.new
    # House.wallFace_selObserver = WallFace_selObserver.new
    House.set_origin_tool_observer = Set_origin_tool_Observer.new
    House.undo_entity_observer = Undo_entity_observer.new
    House.room_observer = Room_observer.new
    House.room_deleted_observer = Room_deleted_observer.new
    
    def self.control_variable_init
      House.filename = ''
      House.is_measure_pause = 0
      House.is_measure_end = 1
      House.current_work = ""
      House.cpoints = []
      House.count = 0 #记录每个绘制对象的已经获得的测量点数
      House.has_dimensioned = 0
      House.last_measure = ""
      House.last_count = 0 
      House.can_undo = 0
    end

    def self.measure_variable_init 
      House.entity_group = []
      House.mpoints = []
      House.axes_tr = nil
      House.wall_id = 0
      House.wall_thickness = 240.mm
      House.cwall = "" #记录当前墙
      House.has_measured_focusedWall = 0
      House.last_entity = []
    end

    def self.set_camera
      #设置view
      eye = Geom::Point3d.new [0,0,15000.mm]
      target  =  Geom::Point3d.new [0,0,0]
      up = Geom::Vector3d.new 0,1,0
      camera = Sketchup::Camera.new eye,target,up,false,45.0
      House.model.active_view.camera = camera
    end

    def self.clear_suModel
      status = House.model.close_active
      House.entities.clear!
      layers = House.model.layers
      layers_size = layers.size
      i = 1
      while (i < layers_size && layers.size > 1)
        layers.remove(i,true)
      end
    end

    def self.create_house(house_attr)   #新开房屋测量
      if house_attr != nil
        self.control_variable_init
        House.house = CHouse.new
        House.Web.canClick = 1
        House.current_work = '创建房屋'
        state="'[Start]开始标注房屋信息'"
        House.Web.execute_script("show("+"#{state}"+")")

        self.set_camera
        
        # House.model.selection.remove_observer(House.wallFace_selObserver)
        # House.model.selection.add_observer(House.wallFace_selObserver)
        #清除已有的model内容
        self.clear_suModel
        
        i = 0
        house_attr.each{ |h|
          if h != ""
            point = [0,i,0]
            House.entities.add_text h.to_s,point
            i += 30.mm
          end
        }
        
        #设置墙的材质
        materials = House.model.materials
        m00_material=materials.add("m00_material")
        file = File.open("#{File.dirname(__FILE__)}\/setting\/rgb",'r') 
        color_array = []
        while line = file.gets   #标准输入流
           line.chop!
           color_array.push(line)
        end
        file.close
        m00_color=[]
        m00_color[0]=color_array[1].to_i
        m00_color[1]=color_array[2].to_i
        m00_color[2]=color_array[3].to_i
        m00_material.color=m00_color
        if materials["material1"] == nil
          materials.add("material1")
        end
        if materials["material2"] == nil
          materials.add("material2")
        end
        self.set_opaque

        House.house.set_name(house_attr) #换成数组20180307
        message = "'房屋信息添加成功！'"
        message =color12
        House.Web.execute_script("showMessage("+"#{message}"+")")
        state = "'[End]房屋信息标注完毕'"
        House.Web.execute_script("show("+"#{state}"+")")
      end
    end

    def self.create_room(room_name)  #创建房间
      if House.is_measure_end == 1  #未开始测量
        House.Web.canClick = 1
        state="'[Start]开始创建房间'"
        House.current_work = '创建房间'
        House.Web.execute_script("show("+"#{state}"+")")
        if room_name != nil
          
          self.measure_variable_init
          se_tool = Set_origin_tool.new
          House.model.select_tool se_tool
          House.model.tools.add_observer(House.set_origin_tool_observer)
          layers = House.model.layers
          House.room = Room.new
          c = 0
          House.house.get["rooms"].each{ |r,v| 
            if /#{room_name}/.match("#{v.get["id"]}")
              c += 1
            end
          }
          if c > 0
            room_name = "#{room_name}#{c}"
          end
          room_layer = layers.add("#{room_name}")
          House.house.set_room(House.room,room_name)
          # puts House.house.get["rooms"]
          puts House.room.get
          House.room.set_id(room_name)
          House.model.active_layer = room_layer
          room_name_text ="'"+"#{room_name}"+"'"
          House.Web.execute_script("create_room_tab("+"#{room_name_text}"+")")

          state="'[End]房间创建完毕'"
          House.Web.execute_script("show("+"#{state}"+")")
          message="'房间创建成功！'"
          House.Web.execute_script("showMessage("+"#{message}"+")")
          #House.current_work = ''         
        end
      else
        UI.messagebox("本次测量尚未完成")
      end
    end

    def self.redraw_model #使用json文件还原model
      if House.house != nil

        # if House.house.get["house_name"] == nil
        #   UI.messagebox("未创建房间")
        #   return
        # end

        hash_file = UI.openpanel("打开数据文件", "c:/", ".mjson")
        if hash_file == nil
          return false
        end
        #puts "#{hash_file}"
        if hash_file =~ /(.*).mjson/
          hash_file = File.read(hash_file)
          house_hash = JSON.parse hash_file
          if house_hash == nil
            return false
          end
          self.set_camera
          # self.clear_suModel

          House.is_measure_end = 1
          House.Web.canClick = 1
          #puts house_hash
          
          # state="'导入房屋'"
          # House.current_work = '导入房屋'
          # House.Web.execute_script("show("+"#{state}"+")")

          if house_hash["version"] == "2.0.0"
            puts origin_tr
            if House.room_tr == nil
              House.room_tr = {}
            end

            se_tool = Redraw_set_origin_tool.new
            House.model.select_tool se_tool
            House.model.tools.add_observer(House.set_origin_tool_observer)
            timer_id = UI.start_timer(0.1,true){
              if House.origin_tr != nil
                UI.stop_timer(timer_id)
                House.house.draw(house_hash)
                rooms = House.house.get["rooms"]
                if rooms.length >= 2
                  House.Web.execute_script("show_combine_room_btn()")
                  # puts 'ttttttt'
                end
                House.Web.execute_script("show_house_info("+"'#{house_hash["house_name"]}'"+")")

                rooms.each{|rname,r|
                  #添加房间tab
                  House.Web.execute_script("create_room_tab("+"'#{r.get["id"]}'"+")")
                  #设置房高
                  House.Web.execute_script("set_room_height("+"'#{r.get["height"]}'"+","+"'#{r.get["id"]}'"+")")
                }
                message="'房屋导入成功！'"
                House.Web.execute_script("showMessage("+"#{message}"+")")
                puts 2
                House.origin_tr = nil
                next #跳过最后一次循环
              end
              # puts 1
            }
          else
            UI.messagebox("请使用2.0.0版本的mjson文件",MB_OK)
          end
        else
          UI.messagebox("这不是一个有效的测量文件",MB_OK)
        end
      else
        message="'请先创建房间！'"
        House.Web.execute_script("showMessage("+"#{message}"+")")
      end
    end

    def self.clear_model
      if House.house != nil        
        self.set_camera
        self.clear_suModel
        House.house = nil
        House.Web.canClick = 1
        message="'房屋清除成功！'"
        House.Web.execute_script("showMessage("+"#{message}"+")")
      end
    end

    def self.start_measure  #开始接收数据
      if House.room != ""
        if House.origin_tr != nil #5表示选择的原点
          if House.is_measure_end != 0
            layers = House.model.layers
            path = "c:\/Users\/" + ENV['USERNAME'] + "\/Documents\/DISTO transfer\/"
            tmpTime = Time.new(2017,1) #查找最新文件
            pfile  = path + "*.dtpro" #需要查找的文件的pattern
            if File.directory?(path)
              Dir.glob(pfile) do |filename| #遍历path下所有dtpro文件
                fmtime = File::mtime(filename)
                  if fmtime >= tmpTime
                    tmpTime = fmtime
                    House.filename =  filename
                  end 
              end  #Dir
            end #File.directory?
            if House.filename != ''
              result = UI.messagebox("确定开始测量？", MB_OKCANCEL)
              if result == IDOK
                #清空测量记录
                # House.measure_record = []  #创建house时初始化
                House.Web.canClick = 1 #
                House.Web.execute_script('clearShow()')      
                House.Web.execute_script('show("准备接收测量点……")')
                #开始测量后改变标志
                House.is_measure_end = 0
                House.entities.add_observer(House.undo_entity_observer)
                House.current_work = ""  
                House.count = 2
                House.measure_option = 0
                Room.reset_num
                self.measure
              else
                House.Web.canClick = 0
              end
            else
              UI.messagebox("没有发现数据文件！", MB_OK)
            end
          else
            UI.messagebox("已开始测量",MB_OK)
          end   
        else
          UI.messagebox("未选择房间原点")
        end
      else 
        UI.messagebox("未创建房间")
      end
    end #start_measure

    def self.reconnect #20180808xuyang
      if House.is_measure_end != 1
        path = "c:\/Users\/" + ENV['USERNAME'] + "\/Documents\/DISTO transfer\/"
        tmpTime = Time.new(2017,1) #查找最新文件
        pfile  = path + "*.dtpro" #需要查找的文件的pattern
        if File.directory?(path)
          Dir.glob(pfile) do |filename| #遍历path下所有dtpro文件
            fmtime = File::mtime(filename)
            if fmtime >= tmpTime
              tmpTime = fmtime
              House.filename =  filename
            end 
          end  #Dir
        end #File.directory?
        if House.filename != ''
          UI.messagebox("重新连接测量仪成功，可以继续测量！", MB_OK)
        elsif
          UI.messagebox("重新连接测量仪失败，请再次尝试连接！", MB_OK)
        end
      end
    end

    def self.end_measure
      if House.is_measure_end != 1
        if House.current_work != ""
          # puts "wrong "
          UI.messagebox("请完成#{House.current_work}后再结束测量", MB_OK)
        else
          result = UI.messagebox("要停止测量吗？", MB_OKCANCEL)
          if result == IDOK
            House.Web.canClick = 1
            House.model.close_active
            layers = House.model.layers
            room_layer_name = House.room.get["id"]
            House.model.active_layer = layers[room_layer_name]
            walls = House.room.get["mobjects"]["BFJO::House::Wall"]
            walls.each{ |wall|
              House.entity_group.push(wall.get["su_model"].get["entity"])
              House.entity_group.push(wall.get["su_model"].get["text"])
            }

            i = 0
            House.entity_group.each{ |e|  
              if e.deleted?
                House.entity_group[i] = nil
              end
              i += 1
            }
            House.entity_group.compact!
            puts House.entity_group

            if House.entity_group != []
              w_group = House.entities.add_group House.entity_group
              w_group.set_attribute "house_mobject","type","room"
              w_group.set_attribute "house_mobject","id",House.room.get["id"]
              w_group.add_observer(House.room_deleted_observer)
              House.room_tr["#{House.room.get["id"]}"] = w_group.transformation
              room_ent_ob = Room_ent_ob.new
              House.room.get["su_model"].set_entity(w_group)
              House.room.get["su_model"].set_entob(room_ent_ob)
              Room.reset_num
              self.save_measure_data
              House.entities.remove_observer(House.undo_entity_observer)
              House.entity_group = []
            end
            self.control_variable_init
            House.origin_tr = nil
          end
        end
      else
          UI.messagebox("还没有开始测量！",MB_OK)
      end
    end

    def self.show_selected_dim
      selection = House.model.selection
      if selection.size == 1
        type = selection[0].get_attribute "house_mobject","type"
        id = selection[0].get_attribute "house_mobject","id"
        id = id.reverse.to_i
        puts type
        puts id
        case type
        when "wall"
          walls = House.room.get["mobjects"]["BFJO::House::Wall"]
          windows = House.room.get["mobjects"]["BFJO::House::Window"]
          doors = House.room.get["mobjects"]["BFJO::House::Door"]
          # puts doors
          # puts windows
          wall = walls[id - 1]
          wall.get["mdimension"].show_dim
          if windows != nil && windows != []
            windows.each{ |window|  
              wid = window.get["wid"].split(",")
              if wid[0].to_i == id || wid[1].to_i == id
                window.get["mdimension"].show_dim
              end
            }
          end
          if doors != nil && doors != []
            doors.each{ |door| 
              if door.get["wid"].to_i == id
                door.get["mdimension"].show_dim
              end
            }
          end
        when "column"
          columns = House.room.get["mobjects"]["BFJO::House::Column"]
          column = columns[id - 1]
          column.get["mdimension"].show_dim
        when "girder"
          girders = House.room.get["mobjects"]["BFJO::House::Girder"]
          girder = girders[id - 1]
          girder.get["mdimension"].show_dim
        else
          UI.messagebox("不是一个正确标注对象（仅能选中墙，柱，梁）")
        end
      else
        UI.messagebox("请仅选择一个尺寸标注对象")
      end
    end

    def self.hide_all_dimension
        walls = House.room.get["mobjects"]["BFJO::House::Wall"]
        if walls != nil && walls != []
          walls.each{|wall|
            wall.get["mdimension"].hide_dim
          }
        end
        windows = House.room.get["mobjects"]["BFJO::House::Window"]
        if windows != nil && windows != []
          windows.each{ |window|  
            window.get["mdimension"].hide_dim
          }
        end
        #门
        doors = House.room.get["mobjects"]["BFJO::House::Door"]
        if doors != nil && doors != []
          doors.each{ |door| 
            door.get["mdimension"].hide_dim
          }
        end
        #柱
        columns = House.room.get["mobjects"]["BFJO::House::Column"]
        if columns != nil && columns !=[]
          columns.each{|column|
            column.get["mdimension"].hide_dim
          }                
        end
        #梁
        girders = House.room.get["mobjects"]["BFJO::House::Girder"]
        if girders != nil && girders != []
          girders.each{|girder|
              girder.get["mdimension"].hide_dim
          } 
        end
    end

    def self.pause_measure
      if House.is_measure_end != 1
        if House.is_measure_pause != 1
          # puts "bbbbbbbbbb"
          if UI.messagebox("暂停测量？",MB_OKCANCEL) == IDOK
            House.Web.canClick = 1
            House.is_measure_pause = 1
            state = "'[暂停测量]'"
            House.Web.execute_script("show("+"#{state}"+")")
          end        
        end
      else
        UI.messagebox("还没有开始测量！",MB_OK)
      end
    end #暂停测量

    def self.continue_measure
      if House.is_measure_end != 1
        if House.is_measure_pause != 0
          if UI.messagebox("继续测量？",MB_OKCANCEL) == IDOK
            House.Web.canClick = 1
            House.is_measure_pause = 0
            state = "'[继续测量]'"
            House.Web.execute_script("show("+"#{state}"+")")
          end
        end
      else
        UI.messagebox("还没有开始测量！",MB_OK)
      end          
    end
    
    def self.read_point_from_dtprofile(datafile)
      dll = Win32API.new(File.dirname(__FILE__)+"\\measure64.dll","readPoint","p","p")
      #转换成字符串
      #datafile为UTF-8编码格式，在调用c# dll的时候，如果路径参数包含中文，dll会识别不了，需要在dll中转换编码
      point = dll.call(datafile.to_s).to_s 
      if point != "false"
        point = point.split(",")
        pointX = ((point[0].to_f)*1000).round.mm
        pointY = ((point[1].to_f)*1000).round.mm
        pointZ = ((point[2].to_f)*1000).round.mm
        #返回3D点
        return Geom::Point3d.new(pointX, pointY, pointZ)
      end
      return false
    end #read_point_from_dtprofile

    def self.measure
      layers = House.model.layers
      file_lastmodify_time_recorded = File::mtime(House.filename) #用于记录文件最后修改时间
      file_lastmodify_time = Time.new #文件最后修改时间
      is_file_modified = 0 #数据文件是否修改，否0，是1
      point = Geom::Point3d.new #从数据文件中获取的点
      state="'已经就绪，准备接收测量点'"
      House.Web.execute_script("show("+"#{state}"+")")  
      state = "'[Start]开始测量地板/天花板<br>默认测量方式：地板一点，天花板一点'"
      House.Web.execute_script("show("+"#{state}"+")")

      timer_id = UI.start_timer(1,true){
        if House.is_measure_end == 1
          House.Web.execute_script('show("结束接收测量点！")')
          UI.stop_timer(timer_id)
          next #跳过最后一次循环
        end
        file_lastmodify_time = File::mtime(House.filename)
        if file_lastmodify_time != file_lastmodify_time_recorded
          is_file_modified = 1
          file_lastmodify_time_recorded = file_lastmodify_time              
        end

        if is_file_modified == 1
          #如果数据文件修改了，就读下一个测量点数据
          point = read_point_from_dtprofile(House.filename)
          is_file_modified = 0
          if point == false
            state = "'不是合法测量仪！'"
            House.Web.execute_script("show("+"#{state}"+")")
            next
          end

          if House.current_work == "" && House.last_measure == ""#误操作提示
            UI.messagebox("请选择测量对象及测量方法再测量")
            next
          end
          #连续测量
          if House.current_work == "" && House.last_measure != ""
            House.current_work = House.last_measure 
            House.count = House.last_count
          end
          if House.is_measure_pause == 0 && point
            if House.axes_tr != nil
              point.transform! House.axes_tr
              point.transform! House.origin_tr
            end
            if House.current_work != ""

              if House.current_work == "wall"
                dist = point.distance_to_plane House.current_floor
                vector = House.room.get["floor_vector"]
                vector1 = vector.reverse
                vector1.length = dist
                tr = Geom::Transformation.translation(vector1)
                point.transform! tr
              end

              if House.cpoints.size > 0
                if point.distance(House.cpoints[House.cpoints.size - 1]) < 1.mm
                  state = "'接收了两个相同的点！'"
                  House.Web.execute_script("show("+"#{state}"+")")
                  next
                end
              end
              # puts House.measure_count[House.current_work][House.measure_option.to_s].to_i,House.measure_option
              i = (House.count - House.measure_count[House.current_work][House.measure_option.to_s].to_i).abs + 1
              #state = "'" + "第#{i}个点" + "[" + House.measure_name_map[House.current_work] + "]" + "：" + "x:" + point.x.to_s+ ";" + "y:" + point.y.to_s + ";" + "z:" + point.z.to_s + "'"
              UI.beep
              current_work_tmp = House.measure_name_map[House.current_work]
              point_x = point.x.to_s
              point_y = point.y.to_s
              point_z = point.z.to_s
              # House.entities.add_cpoint point
              state = "'"+"第#{i}个点"+"[#{current_work_tmp}]:(x:#{point_x},y:#{point_y},z:#{point_z})"+"'"
              House.Web.execute_script("show("+"#{state}"+")")
              House.cpoints.push(point)
              House.count -= 1
              if House.Web.canClick != 0
                House.Web.canClick = 0
              end
            end
            # begin
              if House.current_work == "wall"
                #测墙
                #puts point,House.current_floor
                if House.axes_tr != nil
                  House.model.active_layer = layers["测量点"]
                  ce = House.entities.add_cpoint House.cpoints[House.cpoints.size - 1]
                  House.mpoints.push(ce)
                  House.model.active_layer = layers[0]
                  #如果还未进行坐标转换
                elsif House.axes_tr == nil
                  #接收到两个内墙点
                  if House.count == 1
                    if layers["测量点"] == nil
                      layers.add("测量点")
                    end
                    House.model.active_layer = layers["测量点"]
                    layers["测量点"].visible = true
                    ce = House.entities.add_cpoint House.origin #5为选择
                    House.mpoints.push(ce)
                    House.model.active_layer = layers[0]
                  elsif House.count == 0

                    pt1 = House.cpoints[House.cpoints.size - 2]
                    pt2 = House.cpoints[House.cpoints.size - 1]
                    House.axes_tr = Geometry::reset_axes(pt1,pt2,House.room.get["floor_vector"])
                    House.cpoints[House.cpoints.size-2].transform! House.axes_tr
                    House.cpoints[House.cpoints.size-1].transform! House.axes_tr
                    House.cpoints[House.cpoints.size-2].transform! House.origin_tr
                    House.cpoints[House.cpoints.size-1].transform! House.origin_tr
                    #转换天花板和地板
                    House.current_ceiling[0].transform! House.axes_tr
                    House.current_ceiling[1].transform! House.axes_tr
                    House.current_floor[0].transform! House.axes_tr
                    House.current_floor[1].transform! House.axes_tr
                    House.model.active_layer = layers["测量点"]
                    ce = House.entities.add_cpoint House.cpoints[House.cpoints.size-1]
                    House.mpoints.push(ce)
                    House.model.active_layer = layers[0]

                    House.Web.execute_script("set_endMeasure_btn_visible("+"#{House.count}"+")")
                  end 
                end
                if House.count == 0
                  self.send "measure_#{House.current_work}"
                  House.Web.canClick = 1
                  House.last_measure = House.current_work

                  House.Web.execute_script("set_endMeasure_btn_visible("+"#{House.count}"+")")
                end
              elsif House.current_work == "water_pipe"
                if House.count == 0
                  House.Web.execute_script("enter_water_pipe_radius()")
                  House.Web.canClick = 1

                  House.Web.execute_script("set_endMeasure_btn_visible("+"#{House.count}"+")")
                end
                House.last_measure = House.current_work
              elsif House.count == 0
                # puts "measure_#{House.current_work}"
                House.last_measure = House.current_work
                # puts "last_measure#{House.last_measure}"
                self.send "measure_#{House.current_work}"
                House.Web.canClick = 1
                House.current_work = ""
                House.can_undo = 1

                House.Web.execute_script("set_endMeasure_btn_visible("+"#{House.count}"+")")
              end
            # rescue => err
              # self.exception_handle(err)
            # end
          else
            if point
              UI.messagebox("已暂停测量，请点击继续测量以进行后续测量")
            else
              UI.messagebox("数据点为空")
            end
          end #point
        end #file_modified
      }
    end #self.measure

    #得到墙厚，返回到js
    def self.send_wall_thickness
      thickness="'"+"#{House.wall_thickness.to_mm}"+"'"
      House.Web.execute_script("get_wall_thickness("+"#{thickness}"+")")
    end
    #回退功能，回退功能仅在测量过程中使用，结束测量后不能使用
    def self.undo
      if House.is_measure_end != 1
        # if UI.messagebox("确认回退？",MB_OKCANCEL) == IDOK
        if House.can_undo == 1
          case House.last_measure
          when "wall"
            if House.count % 2 == 0 && House.room.get["mobjects"]["BFJO::House::Wall"].size != 0
              walls = House.room.get["mobjects"]["BFJO::House::Wall"]
              Sketchup.undo
              House.entities.erase_entities House.mpoints[House.mpoints.size - 1]
              House.entities.erase_entities House.mpoints[House.mpoints.size - 2]
              walls.delete_at(walls.size - 1)
              if walls.size > 0
                walls[walls.size - 1].get["su_model"].set_entity(House.last_entity[House.last_entity.size - 1])
              end
              for i in 1..2
                House.mpoints.delete_at(House.mpoints.size - 1)
              end
              House.last_entity.delete_at(House.last_entity.size - 1)
              Wall.num_delete
            else
              UI.messagebox("无法继续回退", MB_OK)
            end
          when "girder"
            Sketchup.undo
            House.entity_group.delete_at(House.entity_group.size - 1)
            girders = House.room.get["mobjects"]["BFJO::House::Girder"]
            girders.delete_at(girders.size - 1)
            Girder.num_delete
          when "column"
            Sketchup.undo
            House.entity_group.delete_at(House.entity_group.size - 1)
            columns = House.room.get["mobjects"]["BFJO::House::Column"]
            columns.delete_at(columns.size - 1)
            Column.num_delete
          when "electricity"
            Sketchup.undo
            electricities = House.room.get["mobjects"]["BFJO::House::Electricity"]
            electricity = electricities[electricities.size - 1]
            # puts electricity.get
            if electricity.get["tag"] != nil
              Sketchup.undo
              House.entity_group.delete_at(House.entity_group.size - 1)
            end
            # puts electricity.get
            # puts "????????????????"
            # puts electricity.get["num"]
            for i in 0..electricity.get["num"] - 1
              House.entity_group.delete_at(House.entity_group.size - 1)
            end
            electricities.delete_at(electricities.size - 1)
            Electricity.num_delete
          when "window"
            walls = House.room.get["mobjects"]["BFJO::House::Wall"]
            windows = House.room.get["mobjects"]["BFJO::House::Window"]
            window = windows[windows.size - 1]
            if window.get["type"] != "L_bay_window"
              s = House.last_entity[House.last_entity.size - 1].get_attribute("house_mobject","id")
              mi = s.reverse.to_i - 1
              Sketchup.undo
              walls[mi].get["su_model"].set_entity(House.last_entity[House.last_entity.size - 1])
              if window.get["type"] == "bay_window"
                House.entity_group.delete_at(House.entity_group.size - 1)
              end
              windows.delete_at(windows.size - 1)
            else
              Sketchup.undo
              # Sketchup.active_model.selection.add House.last_entity[House.last_entity.size - 1]
              s = House.last_entity[House.last_entity.size - 2].get_attribute("house_mobject","id")
              mi1 = s.reverse.to_i - 1
              s = House.last_entity[House.last_entity.size - 1].get_attribute("house_mobject","id")
              mi2 = s.reverse.to_i - 1
              entity1 = House.last_entity[House.last_entity.size - 2]
              entity2 = House.last_entity[House.last_entity.size - 1]
              walls[mi1].get["su_model"].set_entity(entity1)
              walls[mi2].get["su_model"].set_entity(entity2)
              House.entity_group.delete_at(House.entity_group.size - 1)
              House.last_entity.delete_at(House.last_entity.size - 1)
              House.last_entity.delete_at(House.last_entity.size - 1)
              windows.delete_at(windows.size - 1)
            end
            Window.num_delete
          when "door"
            Sketchup.undo
            Sketchup.undo
            walls = House.room.get["mobjects"]["BFJO::House::Wall"]
            s = House.last_entity[House.last_entity.size - 1].get_attribute("house_mobject","id")
            mi = s.reverse.to_i - 1
            doors = House.room.get["mobjects"]["BFJO::House::Door"]
            doors.delete_at(doors.size - 1)
            walls[mi].get["su_model"].set_entity(House.last_entity[House.last_entity.size - 1])
            House.entity_group.delete_at(House.entity_group.size - 1)
            House.last_entity.delete_at(House.last_entity.size - 1)
            Door.num_delete
          when "skirtingline"
            Sketchup.undo
            House.entity_group.delete_at(House.entity_group.size - 1)
            skirtingline = House.room.get["mobjects"]["BFJO::House::Skirtingline"]
            skirtingline.delete_at(skirtingline.size - 1)
          when "tripoint_pipe"
            Sketchup.undo
            House.entity_group.delete_at(House.entity_group.size - 1)
            tripoint_pipes = House.room.get["mobjects"]["BFJO::House::Tripoint_pipe"]
            tripoint_pipes.delete_at(tripoint_pipes.size - 1)
            Tripoint_pipe.num_delete
          when "water_pipe"
            Sketchup.undo
            House.entity_group.delete_at(House.entity_group.size - 1)
            House.entity_group.delete_at(House.entity_group.size - 1)
            water_pipes = House.room.get["mobjects"]["BFJO::House::Water_pipe"]
            water_pipes.delete_at(water_pipes.size - 1)
            Water_pipe.num_delete
          when "ceilingline"
            Sketchup.undo
            House.entity_group.delete_at(House.entity_group.size - 1)
            ceilingline = House.room.get["mobjects"]["BFJO::House::Ceilingline"]
            ceilingline.delete_at(ceilingline.size - 1)
          when "steps"
            Sketchup.undo
            House.entity_group.delete_at(House.entity_group.size - 1)
            steps = House.room.get["mobjects"]["BFJO::House::Steps"]
            steps.delete_at(steps.size - 1)
            Steps.num_delete
          when "suspended_ceiling"
            Sketchup.undo
            House.entity_group.delete_at(House.entity_group.size - 1)
            suspended_ceilings = House.room.get["mobjects"]["BFJO::House::Suspended_ceiling"]
            suspended_ceilings.delete_at(suspended_ceilings.size - 1)
          else
            UI.messagebox("无法回退", MB_OK)
          end
          if House.last_measure == "wall"
            House.can_undo = 1
          else
            House.can_undo = 0
          end
        else
          UI.messagebox("无法继续回退", MB_OK)
        end
        # end
      else
        UI.messagebox("测量已经结束，不能回退！", MB_OK)
      end
    end#回退 

    def self.set_wall_thickness(params)
      House.wall_thickness=params.to_f.mm
      state = "'墙厚度: #{House.wall_thickness},设置成功!'"
      House.Web.execute_script("show("+"#{state}"+")")
    end

    def self.setCurrentWork
      state = "'暂无'"
      if House.current_work != ""
        name =  House.measure_name_map[House.current_work]
        if name != nil
          state = "'"+"测量#{name}"+"'"
        else
          state = "'"+"#{House.current_work}"+"'"
        end
      end
      House.Web.execute_script("setCurrentWork("+"#{state}"+")")
    end

    def self.set_electricity_visible
      sel = House.model.selection
      sel.each{ |se| 
        id = se.get_attribute "house_mobject","id"
        type = se.get_attribute("house_mobject","type")
        if id != nil &&  type == "room"
          sel_entity = se
          id = sel_entity.get_attribute "house_mobject","id"
          House.Web.canClick = 1
          rooms = House.house.get["rooms"]
          room = rooms["#{id}"]
          layer_name = id + "水电"
          layers = House.model.layers
          electricity_layer = layers[layer_name]
          if electricity_layer != nil
            if electricity_layer.visible?
              electricity_layer.visible = false
            else
              electricity_layer.visible = true
            end
          else
            UI.messagebox("该房间没有电器")
          end
          # if room.get["electricity_visible"] == true
          #   room.set_electricity_visible(false)
          #   electricities = room.get["mobjects"]["BFJO::House::Electricity"]
          #   electricities.each{ |electricity|  
          #     electricity.get["su_model"].get["entity"].visible = false
          #   }
          # elsif room.get["electricity_visible"] == false
          #   room.set_electricity_visible(true)
          #   electricities = room.get["mobjects"]["BFJO::House::Electricity"]
          #   electricities.each{ |electricity|  
          #     electricity.get["su_model"].get["entity"].visible = true
          #   }
          # end
        end 
      }
    end

    def self.set_tag_visible
      House.Web.canClick = 1
      layers = House.model.layers
      tag_layer = layers["标签"]
      if tag_layer != nil
        if tag_layer.visible?
          tag_layer.visible = false
        else
          tag_layer.visible = true
        end
      else
        UI.messagebox("该房间没有标签")
      end
    end

    def self.set_transparency
      House.Web.canClick = 1
      material1 = House.model.materials['material1']
      material1.alpha = 0
      material2 = House.model.materials['material2']
      material2.color = [255,255,255]
    end

    def self.set_opaque
      House.Web.canClick = 1
      material1 = House.model.materials['material1']
      material1.alpha = 1
      material1.color = [255,255,255]
      material2 = House.model.materials['material2']
      material2.color = [255,255,255]
    end

    unless file_loaded?(__FILE__)
      path = File.dirname(__FILE__)
      #添加工具栏
      houseMeasure_tool= UI::Toolbar.new "房间测量设计"
      as_hm_cmd = UI::Command.new("房间测量设计") { 
         # puts House.Web.class
         # SKETCHUP_CONSOLE.show
        if House.page_opened_flag == 0
          House.page_opened_flag = 1
          #用于查看调试信息
          House.Web = UIWeb.new
          House.room_tr = {}
          self.set_camera
          self.clear_suModel
          self.get_measure_count
          self.get_electricity_map
          self.get_measure_name_map
          # House.model.selection.add_observer(House.wallFace_selObserver)
          House.Web.add_action_callback("callback") do |dlg, params|
            House.Web.execute(params)
          end

          # House.Web.add_action_callback("reconnect") do |dlg, params|
          #   self.reconnect
          # end #20180808xuyang

          House.Web.add_action_callback("scan_lic_file") do |dlg, params|
            # House.serials = self.scan_lic_file 
            # state = "'"+"#{serials}"+"'"
            # House.Web.execute_script("get_serials("+"#{state}"+")")
            self.get_serials
          end

          House.Web.add_action_callback("add_license") do |dlg, params|
            self.register
            self.get_serials
          end

          House.Web.add_action_callback("set_html_tag") do |dlg, params|
            self.set_html_tag
          end

          House.Web.add_action_callback("set_electricity_visible") do |dlg, params|
            self.set_electricity_visible
          end

          House.Web.add_action_callback("set_tag_visible") do |dlg, params|
            self.set_tag_visible
          end

          #显示尺寸
          House.Web.add_action_callback("show_selected_dim") do |dlg, params|
            self.show_selected_dim
          end

          #隐藏所有尺寸
          House.Web.add_action_callback("hide_all_dimension") do |dlg, params|
            self.hide_all_dimension
          end
          
          

          #点击关闭web
          House.Web.set_on_close{     
              #self.reset
              # House.model.selection.remove_observer(House.wallFace_selObserver)
              House.page_opened_flag = 0
          }
        else
          UI.messagebox("请勿重复打开页面")
        end
      }
      as_hm_cmd.small_icon = path + "/images/home.png"
      as_hm_cmd.large_icon = path + "/images/home.png"
      as_hm_cmd.tooltip = "房间测量设计"
      as_hm_cmd.status_bar_text = "房间测量设计"
      as_hm_cmd.menu_text = "房间测量设计"

      houseMeasure_tool = houseMeasure_tool.add_item as_hm_cmd
      houseMeasure_tool.show

      file_loaded( __FILE__ )
    end
  end #module House
end #module BFJO