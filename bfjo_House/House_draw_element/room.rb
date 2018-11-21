module BFJO
  module House 
    class Room < BFJO::House::MObject
      def initialize
        super
        @floor_vector
        @ceiling_vector
        @suspended_ceiling
        @mobjects = {}
        @height
        @area
        @electricity_visible = true
        @used_to_return["electricity_visible"] = @electricity_visible
      end

      # def set_suspended_ceiling(suspended_ceiling)

      # end

      def set_height(height)
        @height = height
        @used_to_return["height"] = @height
      end

      def set_electricity_visible(flag)
        @electricity_visible = flag
        @used_to_return["electricity_visible"] = @electricity_visible
      end

      def set_floor_vector(floor_vector)
        @floor_vector = floor_vector
        @used_to_return["floor_vector"] = @floor_vector
      end

      def set_ceiling_vector(ceiling_vector)
        @ceiling_vector = ceiling_vector
        @used_to_return["ceiling_vector"] = @ceiling_vector
      end

      def set_mobject(mobject)
        # if @mobjects["#{mobject.class.to_s}"] == nil
          @mobjects["#{mobject.class.to_s}"] ||= []
        # end
        @mobjects["#{mobject.class.to_s}"].push(mobject)
        @used_to_return["mobjects"] = @mobjects
      end

      def set_area(area)
        @area = area
        @used_to_return["area"] = @area
      end

      def self.reset_num
        # @mobjects.each{ |mclass,mobject|
        #   if mclass != "BFJO::House::Skirtingline" && mclass != "BFJO::House::Ceilingline" && mclass != "BFJO::House::Suspended_ceiling"
        #     mobject.reset_num
        #   end
        # }
        Wall.reset_num
        Water_pipe.reset_num
        Window.reset_num
        Door.reset_num
        Column.reset_num
        Electricity.reset_num
        Girder.reset_num
        Steps.reset_num
        Tripoint_pipe.reset_num
      end

      def draw_outline
        layers = House.model.layers
        House.model.start_operation('墙面', true)
        walls = @mobjects["BFJO::House::Wall"]
        cwall = walls[walls.size - 1]
        # puts "????"
        # puts cwall.get
        if walls.size >= 2 #如果有两面以上的墙

          previous_wall = walls[walls.size - 2]
          point1 = previous_wall.get["inner_points"][0]
          point2 = previous_wall.get["inner_points"][1]
          point3 = cwall.get["inner_points"][0]
          point4 = cwall.get["inner_points"][1]
          inner_point = Geometry::intersect_between_lines(point1,point2,point3,point4)
          inner_point1 = [inner_point.x,inner_point.y,inner_point.z]
          previous_wall.set_inner_point(1,inner_point1)
          cwall.set_inner_point(0,inner_point1)

          point1 = previous_wall.get["outter_points"][0]
          point2 = previous_wall.get["outter_points"][1]
          point3 = cwall.get["outter_points"][0]
          point4 = cwall.get["outter_points"][1]
          outter_point = Geometry::intersect_between_lines(point1,point2,point3,point4)
          outter_point1 = [outter_point.x,outter_point.y,outter_point.z]
          previous_wall.set_outter_point(1,outter_point1)
          cwall.set_outter_point(0,outter_point1)

          #重画上一面墙
          pwall_layer = House.room.get["id"] + previous_wall.get["id"]
          layer = layers[pwall_layer]
          House.model.active_layer = layer
          House.entities.erase_entities previous_wall.get["su_model"].get["entity"] #删除上一个内前面轮廓
          inner_wall_1 = House.entities.add_line previous_wall.get["inner_points"][0],previous_wall.get["inner_points"][1]
          inner_wall_1.set_attribute "house_mobject","type","wall_line"
          inner_wall_1.set_attribute "house_mobject","id","#{previous_wall.get["id"]}"
          previous_wall.get["su_model"].set_entity(inner_wall_1)

        end
        wall_layer = House.room.get["id"] + cwall.get["id"]
        layer = layers.add(wall_layer)
        House.model.active_layer = layer
        inner_wall_2 = House.entities.add_line cwall.get["inner_points"][0],cwall.get["inner_points"][1]
        inner_wall_2.set_attribute "house_mobject","type","wall_line"
        inner_wall_2.set_attribute "house_mobject","id","#{cwall.get["id"]}"
        cwall.get["su_model"].set_entity(inner_wall_2)

        House.model.commit_operation
      end
      #直接封闭
      def direct_enclose_wall
        if House.is_measure_end == 0 && House.current_work == "wall"
          if House.count % 2 == 0
            result = UI.messagebox("确定封闭？封闭后结束墙面测量", MB_OKCANCEL)
            if result == IDOK
              House.last_measure = ""
              if House.room.get["mobjects"]["BFJO::House::Wall"].size >= 2
                House.canClick = 1
                layers = House.model.layers
                materials = House.model.materials
                tab_layer_name = "标签"
                tab_layer = layers.add(tab_layer_name)
                walls = @mobjects["BFJO::House::Wall"]
                wall_size = walls.size
                first_wall  = walls[0]
                last_wall = walls[wall_size-1]

                first_wall_inner_p0 = first_wall.get["inner_points"][0]
                floor_face_p0 = [first_wall_inner_p0.x,first_wall_inner_p0.y,first_wall_inner_p0.z-1.mm]


                first_wall_outter_p0 = first_wall.get["outter_points"][0]
                floor_face_p1 = [first_wall_outter_p0.x,first_wall_outter_p0.y,first_wall_outter_p0.z-1.mm]

              

                last_wall_inner_p1 = last_wall.get["inner_points"][1]
                floor_face_pn = [last_wall_inner_p1.x,last_wall_inner_p1.y,last_wall_inner_p1.z-1.mm]



                floor_outter_points = []
                floor_outter_points.push(floor_face_p0)
                floor_outter_points.push(floor_face_p1)
                

                ceiling_outter_points = []
                ceiling_point = House.current_ceiling[0]
                ceiling_vector = House.room.get["ceiling_vector"]
                ceiling_plane = [ceiling_point,ceiling_vector]

                #默认墙是垂直地面的
                
             
                ceiling_face_p0 = floor_face_p0.project_to_plane(ceiling_plane)
                ceiling_face_p0.z += 1.mm


                ceiling_face_p1 = floor_face_p1.project_to_plane(ceiling_plane)
                ceiling_face_p1.z += 1.mm

                ceiling_face_pn = floor_face_pn.project_to_plane(ceiling_plane)
                ceiling_face_pn.z += 1.mm

             

                ceiling_outter_points.push(ceiling_face_p0)
                ceiling_outter_points.push(ceiling_face_p1)


                wall_material1 = materials["innerwall_material"]
                wall_material2 = materials["outterwall_material"]
                plane_material =materials["plane_material"]
                floor_material = materials["floor_material"]

                #重新绘制墙面
                wall_group = []
                i = 0
                walls.each{ |wall|
                  wall_layer_name = @id + wall.get["id"]
                  wall_layer = layers[wall_layer_name]
                  House.model.active_layer = wall_layer
                  House.entities.erase_entities wall.get["su_model"].get["entity"]
                  #获取天花板的一个点
                  point0 = House.current_ceiling[0]
                  point1 = wall.get["inner_points"][0]
                  point2 = wall.get["inner_points"][1]
                  point3 = wall.get["outter_points"][1]
                  point4 = wall.get["outter_points"][0]
                  #puts point4
                  floor_outter_point = [point3.x,point3.y,point3.z]
                  floor_outter_point.z -= 1.mm
                  #puts wall.get[6][0],point4
                  floor_outter_points.push(floor_outter_point)
                  # ceiling_vector = House.room.get["ceiling_vector"]
                  a = ceiling_vector.x
                  b = ceiling_vector.y
                  c = ceiling_vector.z
                  d = -(a * point0.x + b * point0.y + c * point0.z)
                  z5 = -(a * point1.x + b * point1.y + d) / c
                  point5 = [point1.x,point1.y,z5]
                  # puts ">>>>>>>>>>"
                  # puts point1
                  # puts point5
                  # puts "<<<<<<<<<<"
                  z6 = -(a * point2.x + b * point2.y + d) / c
                  point6 = [point2.x,point2.y,z6]
                  z7 = -(a * point3.x + b * point3.y + d) / c
                  point7 = [point3.x,point3.y,z7]
                  z8 = -(a * point4.x + b * point4.y + d) / c
                  point8 = [point4.x,point4.y,z8]

                  # ceiling_outter_point = [point8.x,point8.y,point8.z]

                  ceiling_outter_point = floor_outter_point.project_to_plane(ceiling_plane)
                  ceiling_outter_point.z += 1.mm
                  ceiling_outter_points.push(ceiling_outter_point)

                  wall.set_inner_point(2,point5)
                  wall.set_inner_point(3,point6)
                  wall.set_outter_point(3,point7)
                  wall.set_outter_point(2,point8)
                  #添加6个面
                  inner_wall = House.entities.add_face point1,point5,point6,point2
                  inner_wall.reverse!
                  face1 = House.entities.add_face point1,point2,point3,point4
                  face2 = House.entities.add_face point5,point6,point7,point8
                  face3 = House.entities.add_face point2,point3,point7,point6
                  face4 = House.entities.add_face point3,point4,point8,point7
                  face5 = House.entities.add_face point1,point4,point8,point5

                  #为每个面设置材质
                  inner_wall.material = wall_material2
                  inner_wall.back_material = wall_material1
                  face1.material = wall_material1  #face1到face5的材质设置与inner_wall相反
                  face1.back_material = wall_material2
                  face2.material = wall_material1
                  face2.back_material = wall_material2
                  face3.material = wall_material1
                  face3.back_material = wall_material2
                  face4.material = wall_material1
                  face4.back_material = wall_material2
                  face5.material = wall_material1
                  face5.back_material = wall_material2

                  w_group = House.entities.add_group inner_wall.all_connected
                  w_group.set_attribute "house_mobject","type","wall"
                  w_group.set_attribute "house_mobject","id","#{wall.get["id"]}"
                  puts w_group.get_attribute "house_mobject","type"
                  wall_group.push(w_group)
                  mx = ((point1.x + point2.x) / 2 + (point3.x + point4.x) / 2) / 2
                  my = ((point1.y + point2.y) / 2 + (point3.y + point4.y) / 2) / 2
                  tpoint = [mx,my,point5.z + 10]
                  House.model.active_layer = tab_layer
                  text = House.entities.add_text wall_layer_name,tpoint
                  wall.get["su_model"].set_entity(w_group)
                  wall.get["su_model"].set_text(text)
                  i += 1

                  offset = wall.get["normal_vector"].reverse
                  offset.length = 24
                  wall.get["mdimension"].create_dim(point1,point2,offset,wall.get["id"],"",0)
                }
                #地板的平面
                floor_layer_name = "#{@id}地板"
                floor_layer = layers.add(floor_layer_name)
                House.model.active_layer = floor_layer
                floor_outter_points.push(floor_face_pn)
                floor = House.entities.add_face floor_outter_points
                area = floor.area
                floor.material = floor_material
                floor.back_material = floor_material
                floor = House.entities.add_group floor  #将天花板face作为group，防止后面绘制时all.connected出错
                floor_layer.visible = false

                ceiling_layer_name = "#{@id}天花"
                ceiling_layer = layers.add(ceiling_layer_name)
                House.model.active_layer = ceiling_layer
                #添加最后一个点
                ceiling_outter_points.push(ceiling_face_pn)

                ceiling = House.entities.add_face ceiling_outter_points
                ceiling.reverse!
                ceiling.material = plane_material
                ceiling.back_material = plane_material
                ceiling = House.entities.add_group ceiling
                ceiling_layer.visible = false

                area_round = (area * 0.0254 * 0.0254).round
                set_area(area_round)
                area_text = "'"+"#{area_round}"+"'"
                room_name_text ="'"+"#{@id}"+"'"
                House.Web.execute_script("set_room_area("+"#{area_text}"+","+"#{room_name_text}"+")")

                House.entity_group.push(floor)
                House.entity_group.push(ceiling)
                House.model.active_layer = layers[0]
                layers["测量点"].visible = false
                state = "'[End]墙面测量结束'"
                House.Web.execute_script("show("+"#{state}"+")")
                message="'墙面测量结束'"
                #测量墙结束后显示相关按钮
                House.Web.execute_script("show_hidden_btn("+"#{message}"+","+"4"+")")
                 #隐藏墙面测量按钮
                House.Web.execute_script("hide_shown_component("+"2"+")")
                #还原标志
                House.current_work = ""
                House.last_measure = ""
                House.count = 0

              else
                UI.messagebox("墙的数量过少，无法直接封闭")
              end
            end
          else 
            UI.messagebox("本次测量尚未完成")
          end
        else
          UI.messagebox("测量尚未开始")
        end
      end

      def enclose_wall
        if House.is_measure_end == 0 && House.current_work == "wall"
          if House.count % 2 == 0
            result = UI.messagebox("确定封闭？封闭后结束墙面测量", MB_OKCANCEL)
            if result == IDOK
              House.last_measure = ""
              if House.room.get["mobjects"]["BFJO::House::Wall"].size >= 3

                House.canClick = 1
                layers = House.model.layers
                materials = House.model.materials
                tab_layer_name = "标签"
                tab_layer = layers.add(tab_layer_name)
                walls = @mobjects["BFJO::House::Wall"]
                first_wall = walls[0]
                last_wall = walls[walls.size - 1]
                floor_outter_points = []
                ceiling_outter_points = []

                #计算内外墙面交点
                point1 = first_wall.get["inner_points"][0]
                point2 = first_wall.get["inner_points"][1]
                point3 = last_wall.get["inner_points"][0]
                point4 = last_wall.get["inner_points"][1]
                inner_point = Geometry::intersect_between_lines(point1,point2,point3,point4)
                inner_point1 = [inner_point.x,inner_point.y,inner_point.z]
                first_wall.set_inner_point(0,inner_point1)
                last_wall.set_inner_point(1,inner_point1)

                point1 = first_wall.get["outter_points"][0]
                point2 = first_wall.get["outter_points"][1]
                point3 = last_wall.get["outter_points"][0]
                point4 = last_wall.get["outter_points"][1]
                outter_point = Geometry::intersect_between_lines(point1,point2,point3,point4)
                outter_point1 = [outter_point.x,outter_point.y,outter_point.z]
                first_wall.set_outter_point(0,outter_point1)
                last_wall.set_outter_point(1,outter_point1)

                wall_material1 = materials["material1"]
                wall_material2 = materials["material2"]
                plane_material =materials["plane_material"]
                floor_material = materials["floor_material"]

                #重新绘制墙面
                wall_group = []
                i = 0
                walls.each{ |wall|
                  wall_layer_name = @id + wall.get["id"]
                  wall_layer = layers[wall_layer_name]
                  House.model.active_layer = wall_layer
                  House.entities.erase_entities wall.get["su_model"].get["entity"]
                  #获取天花板的一个点
                  point0 = House.current_ceiling[0]
                  point1 = wall.get["inner_points"][0]
                  point2 = wall.get["inner_points"][1]
                  point3 = wall.get["outter_points"][1]
                  point4 = wall.get["outter_points"][0]
                  #puts point4
                  floor_outter_point = [point4.x,point4.y,point4.z]
                  floor_outter_point.z -= 1.mm
                  #puts wall.get[6][0],point4
                  floor_outter_points.push(floor_outter_point)
                  ceiling_vector = House.room.get["ceiling_vector"]
                  a = ceiling_vector.x
                  b = ceiling_vector.y
                  c = ceiling_vector.z
                  d = -(a * point0.x + b * point0.y + c * point0.z)
                  z5 = -(a * point1.x + b * point1.y + d) / c
                  point5 = [point1.x,point1.y,z5]
                  # puts ">>>>>>>>>>"
                  # puts point1
                  # puts point5
                  # puts "<<<<<<<<<<"
                  z6 = -(a * point2.x + b * point2.y + d) / c
                  point6 = [point2.x,point2.y,z6]
                  z7 = -(a * point3.x + b * point3.y + d) / c
                  point7 = [point3.x,point3.y,z7]
                  z8 = -(a * point4.x + b * point4.y + d) / c
                  point8 = [point4.x,point4.y,z8]

                  ceiling_outter_point = [point8.x,point8.y,point8.z]
                  ceiling_outter_point.z += 1.mm
                  ceiling_outter_points.push(ceiling_outter_point)

                  wall.set_inner_point(2,point5)
                  wall.set_inner_point(3,point6)
                  wall.set_outter_point(3,point7)
                  wall.set_outter_point(2,point8)
                  #添加6个面
                  inner_wall = House.entities.add_face point1,point5,point6,point2
                  inner_wall.reverse!
                  face1 = House.entities.add_face point1,point2,point3,point4
                  face2 = House.entities.add_face point5,point6,point7,point8
                  face3 = House.entities.add_face point2,point3,point7,point6
                  face4 = House.entities.add_face point3,point4,point8,point7
                  face5 = House.entities.add_face point1,point4,point8,point5

                  #为每个面设置材质
                  inner_wall.material = wall_material2
                  inner_wall.back_material = wall_material1
                  face1.material = wall_material1  #face1到face5的材质设置与inner_wall相反
                  face1.back_material = wall_material2
                  face2.material = wall_material1
                  face2.back_material = wall_material2
                  face3.material = wall_material1
                  face3.back_material = wall_material2
                  face4.material = wall_material1
                  face4.back_material = wall_material2
                  face5.material = wall_material1
                  face5.back_material = wall_material2

                  w_group = House.entities.add_group inner_wall.all_connected
                  w_group.set_attribute "house_mobject","type","wall"
                  w_group.set_attribute "house_mobject","id","#{wall.get["id"]}"
                  puts w_group.get_attribute "house_mobject","type"
                  wall_group.push(w_group)
                  mx = ((point1.x + point2.x) / 2 + (point3.x + point4.x) / 2) / 2
                  my = ((point1.y + point2.y) / 2 + (point3.y + point4.y) / 2) / 2
                  tpoint = [mx,my,point5.z + 10]
                  House.model.active_layer = tab_layer
                  text = House.entities.add_text wall_layer_name,tpoint
                  wall.get["su_model"].set_entity(w_group)
                  wall.get["su_model"].set_text(text)
                  i += 1

                  offset = wall.get["normal_vector"].reverse
                  offset.length = 24
                  wall.get["mdimension"].create_dim(point1,point2,offset,wall.get["id"],"redraw_width",1)
                }

                floor_layer_name = "#{@id}地板"
                floor_layer = layers.add(floor_layer_name)
                House.model.active_layer = floor_layer
                floor = House.entities.add_face floor_outter_points
                area = floor.area
                floor.material = floor_material
                floor.back_material = floor_material
                floor = House.entities.add_group floor  #将天花板face作为group，防止后面绘制时all.connected出错
                floor_layer.visible = false

                ceiling_layer_name = "#{@id}天花"
                ceiling_layer = layers.add(ceiling_layer_name)
                House.model.active_layer = ceiling_layer
                ceiling = House.entities.add_face ceiling_outter_points
                ceiling.reverse!
                ceiling.material = plane_material
                ceiling.back_material = plane_material
                ceiling = House.entities.add_group ceiling
                ceiling_layer.visible = false

                area_round = (area * 0.0254 * 0.0254).round
                set_area(area_round)
                area_text = "'"+"#{area_round}"+"'"
                room_name_text ="'"+"#{@id}"+"'"
                House.Web.execute_script("set_room_area("+"#{area_text}"+","+"#{room_name_text}"+")")

                House.entity_group.push(floor)
                House.entity_group.push(ceiling)
                House.model.active_layer = layers[0]
                layers["测量点"].visible = false
                state = "'[End]墙面测量结束'"
                House.Web.execute_script("show("+"#{state}"+")")
                message="'墙面测量结束'"
                #测量墙结束后显示相关按钮
                House.Web.execute_script("show_hidden_btn("+"#{message}"+","+"4"+")")
                 #隐藏墙面测量按钮
                House.Web.execute_script("hide_shown_component("+"2"+")")
                #还原标志
                House.current_work = ""
                House.last_measure = ""
                House.count = 0
              else
                UI.messagebox("墙的数量过少，无法封闭")
              end
            end
          else 
            UI.messagebox("本次测量尚未完成")
          end
        else
          UI.messagebox("测量尚未开始")
        end
      end

      def draw(room_hash)
        layers = House.model.layers
        materials = House.model.materials
        set_id(room_hash["room_name"])
        set_height(room_hash["room_height"].mm.to_mm.round)
        set_floor_vector(Geom::Vector3d.new(room_hash["floor_vector"].x.mm,room_hash["floor_vector"].y.mm,room_hash["floor_vector"].z.mm))
        set_ceiling_vector(Geom::Vector3d.new(room_hash["ceiling_vector"].x.mm,room_hash["ceiling_vector"].y.mm,room_hash["ceiling_vector"].z.mm))
        layers.add("#{@id}")
        if room_hash["walls"] != nil
          floor_points = []
          ceiling_points = []
          room_hash["walls"].each{ |wall_hash|  
            cwall = Wall.new
            cwall.set_data_from_file(wall_hash)
            cwall.get["su_model"].draw(cwall)
            set_mobject(cwall)
            floor_points.push(cwall.get["inner_points"][0])
            ceiling_points.push(cwall.get["inner_points"][2])
          }
          material1 = materials["material1"]
          material2 = materials["material2"]
          plane_material =materials["plane_material"]
          floor_material = materials["floor_material"]
          layers.add("#{@id}地板")
          House.model.active_layer = layers["#{@id}地板"]
          floor_face = House.entities.add_face floor_points
          area = floor_face.area
          floor_face.material = floor_material
          floor_face.back_material = floor_material
          floor_group = House.entities.add_group floor_face
          House.entity_group.push(floor_group)

          ceiling_layer = layers["天花板"]
          if ceiling_layer==nil
            ceiling_layer=layers.add("天花板")
          end
          
          House.model.active_layer = ceiling_layer
          ceiling_face = House.entities.add_face ceiling_points
          ceiling_face.reverse!
          ceiling_face.material = plane_material
          ceiling_face.back_material = plane_material
          ceiling_group = House.entities.add_group ceiling_face
          House.entity_group.push(ceiling_group)

          area_round = (area * 0.0254 * 0.0254).round
          set_area(area_round)
          area_text = "'"+"#{area_round}"+"'"
          room_name_text ="'"+"#{@id}"+"'"
          House.Web.execute_script("set_room_area("+"#{area_text}"+","+"#{room_name_text}"+")")
        end

        if room_hash["doors"] != nil
          room_hash["doors"].each{ |door_hash|  
            door = Door.new
            door.set_data_from_file(door_hash)
            door.get["su_model"].draw(door)
            set_mobject(door)

            layers.add("标签")
            House.model.active_layer = layers["标签"]
            door_text = House.entities.add_text door.get["id"],door.get["points"][2]
            House.entity_group.push(door_text)
          }
        end

        if room_hash["columns"] != nil
          room_hash["columns"].each{ |column_hash|  
            column = Column.new
            column.set_data_from_file(column_hash)
            column.get["su_model"].draw(column)
            set_mobject(column)
          }
        end

        if room_hash["girders"] != nil
          room_hash["girders"].each{ |girder_hash|  
            girder = Girder.new
            girder.set_data_from_file(girder_hash)
            girder.get["su_model"].draw(girder)
            set_mobject(girder)
          }
        end

        if room_hash["steps"] != nil
          room_hash["steps"].each{ |steps_hash|  
            steps = Steps.new
            steps.set_data_from_file(steps_hash)
            steps.get["su_model"].draw(steps)
            set_mobject(steps)
          }
        end

        if room_hash["electricities"] != nil
          room_hash["electricities"].each{ |electricity_hash|  
            electricity = Electricity.new
            electricity.set_data_from_file(electricity_hash)
            electricity.get["su_model"].draw(electricity)
            set_mobject(electricity)

            if electricity.get["tag"] != nil
              layers.add("标签")
              House.model.active_layer = layers["标签"]
              text = House.entities.add_text electricity.get["tag"],electricity.get["points"][0]
              House.entity_group.push(text)
            end
          }
        end

        if room_hash["skirtingline"] != nil
          skirtingline = Skirtingline.new
          skirtingline_hash = room_hash["skirtingline"]
          skirtingline.set_data_from_file(skirtingline_hash)
          skirtingline.get["su_model"].draw(skirtingline)
          set_mobject(skirtingline)
        end

        if room_hash["ceilingline"] != nil
          ceilingline = Ceilingline.new
          ceilingline_hash = room_hash["ceilingline"]
          ceilingline.set_data_from_file(ceilingline_hash)
          ceilingline.get["su_model"].draw(ceilingline)
          set_mobject(ceilingline)
        end

        if room_hash["tripoint_pipes"] != nil
          room_hash["tripoint_pipes"].each{ |tripoint_pipe_hash|  
            tripoint_pipe = Tripoint_pipe.new
            tripoint_pipe.set_data_from_file(tripoint_pipe_hash)
            tripoint_pipe.get["su_model"].draw(tripoint_pipe)
            set_mobject(tripoint_pipe)
          }
        end

        if room_hash["water_pipes"] != nil
          room_hash["water_pipes"].each{ |water_pipe_hash|  
            water_pipe = Water_pipe.new
            water_pipe.set_data_from_file(water_pipe_hash)
            water_pipe.get["su_model"].draw(water_pipe)
            set_mobject(water_pipe)
          }
        end

        if room_hash["windows"] != nil
          room_hash["windows"].each{ |window_hash|
            window = Window.new
            window.set_data_from_file(window_hash)
            window.get["su_model"].draw(window)
            set_mobject(window)
          }
        end

        if room_hash["suspended_ceilings"] != nil
          room_hash["suspended_ceilings"].each{ |suspended_ceiling_hash|
            suspended_ceiling = Suspended_ceiling.new
            suspended_ceiling.set_data_from_file(suspended_ceiling_hash)
            suspended_ceiling.get["su_model"].draw(suspended_ceiling)
            set_mobject(suspended_ceiling)
          }
        end

        if @mobjects["BFJO::House::Wall"] != []
          @mobjects["BFJO::House::Wall"].each{ |wall|  
            House.entity_group.push(wall.get["su_model"].get["entity"])
            House.entity_group.push(wall.get["su_model"].get["text"])
          }
        end
        House.model.active_layer = layers["#{@id}"]
        room_group = House.entities.add_group House.entity_group
        room_group.add_observer(House.room_deleted_observer)
        House.room_tr["#{@id}"] = room_group.transformation
        room_group.set_attribute "house_mobject","type","room"
        room_group.set_attribute "house_mobject","id",@id
        @su_model.set_entity(room_group)
        room_ent_ob = Room_ent_ob.new
        @su_model.set_entob(room_ent_ob)
        Room.reset_num
        # @group = room_group
      end
    end
  end
end