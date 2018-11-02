module BFJO
  module House    
    
    #标注尺寸
    def self.room_dimensioning #xuyang170826
      #if Kitchencountertop.has_measured == 1
      if House.current_work == ""
        # state="'[Start]标注尺寸'"
        # House.Web.execute_script("show("+"#{state}"+")")
        model = Sketchup.active_model
        entities = model.active_entities
        layers = model.layers
        dlayer = layers["Room Dimension"]
        model.active_layer = layers[0] #xuyang170826
        House.canClick=1
        #如果存在name='dimension Layer'的层，则删除该层，否则创建标注尺寸层
        if dlayer && House.has_dimensioned == 1

          if dlayer != nil #xuyang170829
            model.layers.remove("Room Dimension", true) 
          end
          House.has_dimensioned = 0
          state="'隐藏房屋尺寸'"
          House.Web.execute_script("show("+"#{state}"+")")
          
        elsif House.has_dimensioned != 1

          state="'[Start]标注尺寸'"
          House.Web.execute_script("show("+"#{state}"+")")
          #xuyang170826
          if dlayer != nil
            model.layers.remove("Room Dimension", true) 
          end
          dlayer = layers.add("Room Dimension")
          model.active_layer = dlayer

          walls = House.room.get[1]
          walls.each{ |wall|
            v0 = wall.get[5][0]
            v1 = wall.get[5][1]
            #计算dimension的向量
            delta = v1.x - v0.x
            if delta != 0
              b = (v1.x * v0.y  - v0.x * v1.y ) / delta
              k = (v1.y - v0.y) / delta
              a = 20.0
              vector_line = Geom::Vector3d.new v0.x,v0.y - b,0
              vector_line.normalize!
              vec = Geom::Vector3d.new -(a * vector_line.y / vector_line.x),a,0
              vector = vec
              vector.normalize!
              x = vector.x * 20
              y = vector.y * 20
              vector.set!(x,y,0)
              if delta > 0
                vector.reverse!
              end
            else 
              vec = Geom::Vector3d.new 20,0,0
              vector = vec             
              #vector.normalize!
              if v1.y < v0.y
                vector.reverse!
              end
            end
            dim = entities.add_dimension_linear v0,v1,vector
            dim.text_position = Sketchup::DimensionLinear::TEXT_CENTERED
            dim.has_aligned_text = true
          }

          House.has_dimensioned = 1

          state="'[End]标注尺寸完成'"
          House.Web.execute_script("show("+"#{state}"+")")

          message="'标注尺寸成功'"
          House.Web.execute_script("showMessage("+"#{message}"+")")
                    
        end#Kitchencountertop.has_dimensioned
      else
        UI.messagebox("请先完成当前#{House.current_work}工作，再继续。", MB_OK)
      end # if $is_current_work_done == 1
    end #measure_dimensioning

    #修改墙厚度
    def self.start_modify_wall 
      if House.is_measure_end == 1 && House.is_measure_wall_end == 1
        if House.cwall != ""
          House.canClick=1
          thickness="'"+"#{House.cwall.get[2]}"+"'"
          House.Web.execute_script("get_wall_thickness("+"#{thickness}"+")") 
          state="'[Start]墙厚设置'"
          House.Web.execute_script("show("+"#{state}"+")")  
        else
          UI.messagebox("未选中墙面")
        end
      else
        if House.is_measure_wall_end != 1
          UI.messagebox("未进行过墙面测量")
        else
          UI.messagebox("请在结束测量后进行")
        end
      end
    end

    def self.modify_wall
      if House.cwall != ""
        House.cwall.set_thickness(House.Web.get_element_value("wall_thickness_resetInput").to_f.mm)
        ly_name = House.cwall.get[4][0].layer.name
        puts ly_name
        ######需要先获取House.room
        cwall_id = House.cwall.get[0].to_i
        walls = House.room.get[1]
        model = Sketchup.active_model
        entities = model.active_entities
        layers = model.layers
        point1 = House.cwall.get[5][0]
        point2 = House.cwall.get[5][1]
        #计算墙面法向量使其模为墙的厚度
        wall_vector = House.cwall.get[3]
        wall_vector.length = House.cwall.get[2]
        #wall_vector.reverse!  #####
        House.cwall.set_normal_vector(wall_vector)
        #内墙面两点向墙面法向量方向平移得外墙面2点
        tr1 = Geom::Transformation.translation(wall_vector)
        point3 = point1.transform tr1
        point4 = point2.transform tr1
        #为wall实例赋值
        ceiling_vector = House.room.get[3]
        point0 = House.current_ceiling[0]
        a = ceiling_vector.x
        b = ceiling_vector.y
        c = ceiling_vector.z
        d = -(a * point0.x + b * point0.y + c * point0.z)
        z1 = -(a * point3.x + b * point3.y + d) / c
        point5 = [point3.x,point3.y,z1]
        z2 = -(a * point4.x + b * point4.y + d) / c
        point6 = [point4.x,point4.y,z2]
        House.cwall.set_outter_point(0,point3)
        House.cwall.set_outter_point(1,point4)
        House.cwall.set_outter_point(2,point5)
        House.cwall.set_outter_point(3,point6)
        if cwall_id == 1
          previous_wall = walls[walls.size - 1]
          next_wall = walls[1]
        elsif cwall_id == walls.size
          previous_wall = walls[walls.size - 2]
          next_wall = walls[0]
        else
          previous_wall = walls[cwall_id - 2]
          next_wall = walls[cwall_id]
        end 
        #擦除旧墙面
        entities.erase_entities House.cwall.get[4][0]
        entities.erase_entities House.cwall.get[4][1]
        entities.erase_entities previous_wall.get[4][0]
        entities.erase_entities previous_wall.get[4][1]
        entities.erase_entities next_wall.get[4][0]
        entities.erase_entities next_wall.get[4][1]
        #计算当前墙与上一面墙内外墙面交点
        outter_point = Geometry::intersect_between_lines(House.cwall.get[6][0],House.cwall.get[6][1],previous_wall.get[6][0],previous_wall.get[6][1])
        z = -(a * outter_point.x + b * outter_point.y + d) / c
        point = Geom::Point3d.new(outter_point.x,outter_point.y,z)
        House.cwall.set_outter_point(0,outter_point)
        House.cwall.set_outter_point(2,point)
        previous_wall.set_outter_point(1,outter_point)    
        previous_wall.set_outter_point(3,point)
        #重新绘制上一个墙面
        p_wall_layer = "#{House.room.get[0]}墙" + previous_wall.get[0].to_s
        layer1 = layers[p_wall_layer]
        model.active_layer = layer1
        point1 = previous_wall.get[5][0]
        point2 = previous_wall.get[5][1]
        point3 = previous_wall.get[6][1]
        point4 = previous_wall.get[6][0]
        point5 = previous_wall.get[5][2]
        point6 = previous_wall.get[5][3]
        point7 = previous_wall.get[6][3]
        point8 = previous_wall.get[6][2]
        #puts point5,point6,point7,point8
        inner_wall = entities.add_face point1,point5,point6,point2
        face1 = entities.add_face point1,point2,point3,point4
        face2 = entities.add_face point5,point6,point7,point8
        face3 = entities.add_face point2,point3,point7,point6
        face4 = entities.add_face point3,point4,point8,point7
        face5 = entities.add_face point1,point4,point8,point5
        inner_wall.reverse!
        face1.reverse!
        face2.reverse!
        face3.reverse!
        face4.reverse!
        face5.reverse!
        p_group = entities.add_group inner_wall.all_connected
        #UI.messagebox("aaaaa")
        mx = ((previous_wall.get[5][0].x + previous_wall.get[5][1].x) / 2 + (previous_wall.get[6][0].x + previous_wall.get[6][1].x) / 2) / 2
        my = ((previous_wall.get[5][0].y + previous_wall.get[5][1].y) / 2 + (previous_wall.get[6][0].y + previous_wall.get[6][1].y) / 2) / 2
        tpoint = [mx,my,z + 10]
        text = entities.add_text p_wall_layer,tpoint
        if previous_wall.get[7] != []
          previous_wall.get[7].each{ |window|
            if window.get[1] == "normal_window"
              point1 = window.get[0][0]
              point2 = window.get[0][1]
              point3 = [point1.x,point1.y,point2.z]
              point4 = [point2.x,point2.y,point1.z]
              #门厚度与墙相同
              thickness = previous_wall.get[2]
              face = entities.add_face point1,point4,point2,point3
              vector = face.normal
              vector.normalize!
              w_vector = previous_wall.get[3]
              w_vector.normalize!
              if vector.angle_between(w_vector) > 1.57
                face.reverse!
              end
              face.pushpull thickness
              c_entity = entities.add_group face.all_connected
              p_group = c_entity.subtract(p_group)
            elsif window.get[1] == "bay_window" || window.get[1] == "L_bay_window"
              if window.get[2] != ""
                entities.erase_entities window.get[2]
              end
              wall_thickness_n = previous_wall.get[2]
              i_plane = [previous_wall.get[5][0],previous_wall.get[3]]
              dis = window.get[0][2].distance_to_plane i_plane
              #entities = Sketchup.active_model.active_entities
              puts dis,wall_thickness_n
              wall_layer = "#{House.room.get[0]}墙" + previous_wall.get[0].to_s
              layer = layers[wall_layer]
              model.active_layer = layer
              if dis <= wall_thickness_n
                point1 = window.get[0][0]
                point3 = window.get[0][1]
                point2 = [point1.x,point1.y,point3.z]
                point4 = [point3.x,point3.y,point1.z]
                window_face = entities.add_face point1,point2,point3,point4
                window_face.reverse!
                #wall_thickness_n += 0.001.mm
                window_face.pushpull wall_thickness_n
                window_entity = entities.add_group window_face.all_connected
                #wall_entity = previous_wall.get[4][0]
                p_group = window_entity.subtract(p_group)
                window.set_entity("")
                #text = previous_wall.get[4][1]
                #self.find_inner_wall_face(previous_wall,result,text)
              else
                point1 = window.get[0][0]
                point3 = window.get[0][1]
                point2 = [point1.x,point1.y,point3.z]
                point4 = [point3.x,point3.y,point1.z]
                window_face = entities.add_face point1,point2,point3,point4
                window_face.reverse!
                #wall_thickness_n += 0.001.mm
                window_face.pushpull wall_thickness_n
                window_entity = entities.add_group window_face.all_connected
                #wall_entity = previous_wall.get[4][0]
                p_group = window_entity.subtract(p_group)
                #text = previous_wall.get[4][1]
                #self.find_inner_wall_face(previous_wall,result,text)
                differ = dis - wall_thickness_n
                window_face = entities.add_face point1,point2,point3,point4
                window_face.reverse!
                window_face.pushpull differ
                window_entity = entities.add_group window_face.all_connected
                vec = previous_wall.get[3]
                #vec = vec.reverse
                vec.length = wall_thickness_n
                tr = Geom::Transformation.translation(vec)
                window_entity.transform! tr
                window.set_entity(window_entity)
              end
            end
          }
        end
        if previous_wall.get[8] != []
          previous_wall.get[8].each{ |door|
            point1 = door.get[0][0]
            point2 = door.get[0][1]
            point3 = [point1.x,point1.y,point2.z]
            point4 = [point2.x,point2.y,point1.z]
            #门厚度与墙相同
            thickness = previous_wall.get[2]
            face = entities.add_face point1,point4,point2,point3
            vector = face.normal
            vector.normalize!
            w_vector = previous_wall.get[3]
            w_vector.normalize!
            if vector.angle_between(w_vector) > 1.57
              face.reverse!
            end
            face.pushpull thickness
            c_entity = entities.add_group face.all_connected
            p_group = c_entity.subtract(p_group)
          }
        end
        self.find_inner_wall_face(previous_wall,p_group,text)
        # puts previous_wall.get[4][2].entityID
        outter_point = Geometry::intersect_between_lines(next_wall.get[6][0],next_wall.get[6][1],House.cwall.get[6][0],House.cwall.get[6][1])
        z = -(a * outter_point.x + b * outter_point.y + d) / c
        point = Geom::Point3d.new(outter_point.x,outter_point.y,z)
        next_wall.set_outter_point(0,outter_point)
        next_wall.set_outter_point(2,point)
        House.cwall.set_outter_point(1,outter_point)
        House.cwall.set_outter_point(3,point)
        #重新绘制下一个墙面
        n_wall_layer = "#{House.room.get[0]}墙" + next_wall.get[0].to_s
        layer2 = layers[n_wall_layer]
        model.active_layer = layer2
        point1 = next_wall.get[5][0]
        point2 = next_wall.get[5][1]
        point3 = next_wall.get[6][1]
        point4 = next_wall.get[6][0]
        point5 = next_wall.get[5][2]
        point6 = next_wall.get[5][3]
        point7 = next_wall.get[6][3]
        point8 = next_wall.get[6][2]
        inner_wall = entities.add_face point1,point5,point6,point2
        face1 = entities.add_face point1,point2,point3,point4
        face2 = entities.add_face point5,point6,point7,point8
        face3 = entities.add_face point2,point3,point7,point6
        face4 = entities.add_face point3,point4,point8,point7
        face5 = entities.add_face point1,point4,point8,point5
        inner_wall.reverse!
        face1.reverse!
        face2.reverse!
        face3.reverse!
        face4.reverse!
        face5.reverse!
        n_group = entities.add_group inner_wall.all_connected
        mx = ((next_wall.get[5][0].x + next_wall.get[5][1].x) / 2 + (next_wall.get[6][0].x + next_wall.get[6][1].x) / 2) / 2
        my = ((next_wall.get[5][0].y + next_wall.get[5][1].y) / 2 + (next_wall.get[6][0].y + next_wall.get[6][1].y) / 2) / 2
        tpoint = [mx,my,z + 10]
        text = entities.add_text n_wall_layer,tpoint
        #UI.messagebox("bbbbb")
        if next_wall.get[7] != []
          next_wall.get[7].each{ |window|
            if window.get[1] == "normal_window"
              point1 = window.get[0][0]
              point2 = window.get[0][1]
              point3 = [point1.x,point1.y,point2.z]
              point4 = [point2.x,point2.y,point1.z]
              #门厚度与墙相同
              thickness = next_wall.get[2]
              face = entities.add_face point1,point4,point2,point3
              vector = face.normal
              vector.normalize!
              w_vector = next_wall.get[3]
              w_vector.normalize!
              if vector.angle_between(w_vector) > 1.57
                face.reverse!
              end
              face.pushpull thickness
              c_entity = entities.add_group face.all_connected
              n_group = c_entity.subtract(n_group)
            elsif window.get[1] == "bay_window" || window.get[1] == "L_bay_window"
              if window.get[2] != ""
                entities.erase_entities window.get[2]
              end
              wall_thickness_n = next_wall.get[2]
              i_plane = [next_wall.get[5][0],next_wall.get[3]]
              dis = window.get[0][2].distance_to_plane i_plane
              #entities = Sketchup.active_model.active_entities
              puts dis,wall_thickness_n
              wall_layer = "#{House.room.get[0]}墙" + next_wall.get[0].to_s
              layer = layers[wall_layer]
              model.active_layer = layer
              if dis <= wall_thickness_n
                point1 = window.get[0][0]
                point3 = window.get[0][1]
                point2 = [point1.x,point1.y,point3.z]
                point4 = [point3.x,point3.y,point1.z]
                window_face = entities.add_face point1,point2,point3,point4
                window_face.reverse!
                window_face.pushpull wall_thickness_n
                window_entity = entities.add_group window_face.all_connected
                #wall_entity = next_wall.get[4][0]
                n_group = window_entity.subtract(n_group)
                window.set_entity("")
                #text = next_wall.get[4][1]
                #self.find_inner_wall_face(next_wall,result,text)
              else
                point1 = window.get[0][0]
                point3 = window.get[0][1]
                point2 = [point1.x,point1.y,point3.z]
                point4 = [point3.x,point3.y,point1.z]
                window_face = entities.add_face point1,point2,point3,point4
                window_face.reverse!
                window_face.pushpull wall_thickness_n
                window_entity = entities.add_group window_face.all_connected
                #wall_entity = next_wall.get[4][0]
                n_group = window_entity.subtract(n_group)
                #text = next_wall.get[4][1]
                #self.find_inner_wall_face(next_wall,result,text)
                differ = dis - wall_thickness_n
                window_face = entities.add_face point1,point2,point3,point4
                window_face.reverse!
                window_face.pushpull differ
                window_entity = entities.add_group window_face.all_connected
                vec = next_wall.get[3]
                #vec = vec.reverse
                vec.length = wall_thickness_n
                tr = Geom::Transformation.translation(vec)
                window_entity.transform! tr
                window.set_entity(window_entity)
              end
            end
          }
        end
        if next_wall.get[8] != []
          next_wall.get[8].each{ |door|
            point1 = door.get[0][0]
            point2 = door.get[0][1]
            point3 = [point1.x,point1.y,point2.z]
            point4 = [point2.x,point2.y,point1.z]
            #门厚度与墙相同
            thickness = next_wall.get[2]
            face = entities.add_face point1,point4,point2,point3
            vector = face.normal
            vector.normalize!
            w_vector = next_wall.get[3]
            w_vector.normalize!
            if vector.angle_between(w_vector) > 1.57
              face.reverse!
            end
            face.pushpull thickness
            c_entity = entities.add_group face.all_connected
            n_group = c_entity.subtract(n_group)
          }
        end
        self.find_inner_wall_face(next_wall,n_group,text)
        #重新绘制当前墙面
        c_wall_layer = "#{House.room.get[0]}墙" + House.cwall.get[0].to_s
        layer3 = layers[c_wall_layer]
        model.active_layer = layer3
        point1 = House.cwall.get[5][0]
        point2 = House.cwall.get[5][1]
        point3 = House.cwall.get[6][1]
        point4 = House.cwall.get[6][0]
        point5 = House.cwall.get[5][2]
        point6 = House.cwall.get[5][3]
        point7 = House.cwall.get[6][3]
        point8 = House.cwall.get[6][2]
        inner_wall = entities.add_face point1,point5,point6,point2
        face1 = entities.add_face point1,point2,point3,point4
        face2 = entities.add_face point5,point6,point7,point8
        face3 = entities.add_face point2,point3,point7,point6
        face4 = entities.add_face point3,point4,point8,point7
        face5 = entities.add_face point1,point4,point8,point5
        inner_wall.reverse!
        face1.reverse!
        face2.reverse!
        face3.reverse!
        face4.reverse!
        face5.reverse!
        c_group = entities.add_group inner_wall.all_connected
        mx = ((House.cwall.get[5][0].x + House.cwall.get[5][1].x) / 2 + (House.cwall.get[6][0].x + House.cwall.get[6][1].x) / 2) / 2
        my = ((House.cwall.get[5][0].y + House.cwall.get[5][1].y) / 2 + (House.cwall.get[6][0].y + House.cwall.get[6][1].y) / 2) / 2
        tpoint = [mx,my,z + 10]
        text = entities.add_text c_wall_layer,tpoint
        #UI.messagebox("cccccc")
        if House.cwall.get[7] != []
          House.cwall.get[7].each{ |window|
            if window.get[1] == "normal_window"
              point1 = window.get[0][0]
              point2 = window.get[0][1]
              point3 = [point1.x,point1.y,point2.z]
              point4 = [point2.x,point2.y,point1.z]
              #门厚度与墙相同
              thickness = House.cwall.get[2]
              face = entities.add_face point1,point4,point2,point3
              vector = face.normal
              vector.normalize!
              w_vector = House.cwall.get[3]
              w_vector.normalize!
              if vector.angle_between(w_vector) > 1.57
                face.reverse!
              end
              face.pushpull thickness
              c_entity = entities.add_group face.all_connected
              c_group = c_entity.subtract(c_group)
            elsif window.get[1] == "bay_window" || window.get[1] == "L_bay_window"
              if window.get[2] != ""
                entities.erase_entities window.get[2]
              end
              wall_thickness_n = House.cwall.get[2]
              i_plane = [House.cwall.get[5][0],House.cwall.get[3]]
              dis = window.get[0][2].distance_to_plane i_plane
              #entities = Sketchup.active_model.active_entities
              puts dis,wall_thickness_n
              wall_layer = "#{House.room.get[0]}墙" + House.cwall.get[0].to_s
              layer = layers[wall_layer]
              model.active_layer = layer
              if dis <= wall_thickness_n
                point1 = window.get[0][0]
                point3 = window.get[0][1]
                point2 = [point1.x,point1.y,point3.z]
                point4 = [point3.x,point3.y,point1.z]
                window_face = entities.add_face point1,point2,point3,point4
                window_face.reverse!
                window_face.pushpull wall_thickness_n
                window_entity = entities.add_group window_face.all_connected
                #wall_entity = House.cwall.get[4][0]
                c_group = window_entity.subtract(c_group)
                window.set_entity("")
                #text = House.cwall.get[4][1]
                #self.find_inner_wall_face(House.cwall,result,text)
              else
                point1 = window.get[0][0]
                point3 = window.get[0][1]
                point2 = [point1.x,point1.y,point3.z]
                point4 = [point3.x,point3.y,point1.z]
                window_face = entities.add_face point1,point2,point3,point4
                window_face.reverse!
                window_face.pushpull wall_thickness_n
                window_entity = entities.add_group window_face.all_connected
                #wall_entity = House.cwall.get[4][0]
                c_group = window_entity.subtract(c_group)
                #text = House.cwall.get[4][1]
                #self.find_inner_wall_face(House.cwall,result,text)
                differ = dis - wall_thickness_n
                window_face = entities.add_face point1,point2,point3,point4
                window_face.reverse!
                window_face.pushpull differ
                window_entity = entities.add_group window_face.all_connected
                vec = House.cwall.get[3]
                #vec = vec.reverse
                vec.length = wall_thickness_n
                tr = Geom::Transformation.translation(vec)
                window_entity.transform! tr
                window.set_entity(window_entity)
              end
            end
          }
        end
        if House.cwall.get[8] != []
          House.cwall.get[8].each{ |door|
            point1 = door.get[0][0]
            point2 = door.get[0][1]
            point3 = [point1.x,point1.y,point2.z]
            point4 = [point2.x,point2.y,point1.z]
            #门厚度与墙相同
            thickness = House.cwall.get[2]
            face = entities.add_face point1,point4,point2,point3
            vector = face.normal
            vector.normalize!
            w_vector = House.cwall.get[3]
            w_vector.normalize!
            if vector.angle_between(w_vector) > 1.57
              face.reverse!
            end
            face.pushpull thickness
            #标记
            c_entity = entities.add_group face.all_connected
            c_group = c_entity.subtract(c_group)
          }
        end
        self.find_inner_wall_face(House.cwall,c_group,text)
        puts House.cwall.get[4][2].entityID
        #puts House.room.get[4]
        model.active_layer = layers[0]
        state="'[End]墙厚设置完成'"
        House.Web.execute_script("show("+"#{state}"+")")
        message="'墙厚设置成功'"
        House.Web.execute_script("showMessage("+"#{message}"+")")
        House.cwall = ""
        #model.selection.add_observer(House.wallFace_selObserver)
      else
      UI.messagebox("未选中墙面")
      end         
    end

    #墙面聚焦
    def self.focus_wallFace
      model = Sketchup.active_model
      entities = model.entities
      layers = model.layers
      layer = model.active_layer
      #room_layer_name = 'room '+ House.room.get[0].to_s
      
      if layer != layers['Layer0']  
         model.active_layer = layers['Layer0']     
      end
      
      #current_wall = WallFace_selObserver.get_current_wall
      current_wallFace = WallFace_selObserver.get_wallFace

      #如果已选中，则保留当前所选中的墙面所连接的实体
      if current_wallFace != nil
        wallFace_connected_ents = current_wallFace.all_connected
        #当单独打开一个sketchup文件时，是没有House.room这个对象的，所以当作异常来执行
        begin
          walls = House.room.get[1]
          #得到当前所选墙面所属的墙 @@current_wall
          walls.each{|wall|
            ens = wall.get[4][0].entities
            ens.each { |ent|
              if ent.entityID == current_wallFace.entityID
                current_wall = wall
                WallFace_selObserver.set_current_wall(wall)
                break
              end
            }
          }
        rescue
          #捕获异常
        end    
      end
      if current_wallFace == nil
        UI.messagebox('您还未选择墙面')
      else
        House.canClick = 1
        if WallFace_selObserver.get_is_hide == 0
          wallFace_layer = current_wallFace.layer
          camera = Sketchup::Camera.new
          camera = model.active_view.camera
          eye = camera.eye
          target = camera.target
          up = camera.up
          House.last_camera.set eye, target, up
          model.active_view.camera = House.last_camera

          layers.each{|layer|
            if layer.name != wallFace_layer.name && layer.name[0..3] != 'room'
               layer.visible = false
            end
          }
          #walls = House.room.get[1]
        
          entities.each{ |e|
            if e.attribute_dictionary("column_owner_wall") != nil
              if e.attribute_dictionary("column_owner_wall").size == 2
                e.attribute_dictionary("column_owner_wall").each{ |key,value| 
                  puts key,value
                  e.layer.visible = true
                  entities.each{ |e2|
                    puts current_wallFace.layer.name[4].to_i
                    if e2.get_attribute("wall","id") == value && current_wallFace.layer.name[4].to_i != value                   
                    WallFace_selObserver.set_other_connected_wall(e2)
                      e2.visible = false            
                    end
                  }
                }
              end
          end
          }
          wallFace_connected_ents.each{|ent|
           # if (ent.is_a? Sketchup::Face) || (ent.is_a? Sketchup::Edge)          
                if ent.entityID != current_wallFace.entityID
                   ent.visible = false
                end             
           # end       
          }
          edges = current_wallFace.edges
          edges.each{|edge|
            edge.visible = true
          }
          begin
            selected_wall_attr = House.cwall.get_wall_and_connected_attr
            House.Web.execute_script("show_in_table("+"#{selected_wall_attr}"+")")  
          rescue 
            #puts "标注尺寸及查看相关墙属性功能在独立文件中尚未实现"
          end
         
         #  begin
         #    if House.cwall.get_wall_and_connected_attr !=nil
         #      selected_wall_attr = House.cwall.get_wall_and_connected_attr
         #    House.Web.execute_script("show_in_table("+"#{selected_wall_attr}"+")")  
         #    end
          # rescue
          # end
          #设置视角view
          wall_face_vector = current_wallFace.normal.reverse
          vertices = current_wallFace.vertices             
          boundingbox = current_wallFace.bounds     
          target = boundingbox.center
          wall_face_vector.length = 15000.mm
          transform = Geom::Transformation.translation(wall_face_vector)        
          eye = target.transform transform
          up  = Geom::Vector3d.new 0,0,1
          #当选择水平墙面的时候会抛出异常，因为up已经设成了(0,0,1)。在这里捕获异常
          camera_set_right = true
          begin
            camera = Sketchup::Camera.new eye,target,up,true,45.0              
          rescue
            camera_set_right = false
          end
          if camera_set_right
            model.active_view.camera = camera
          else
            UI.messagebox("请选择正确的内墙面！")
          end
          WallFace_selObserver.set_is_hide(1)
        else #is_hide=1
          begin
          #先还原所有实体的可见性；注：墙拥有的实体不属于房间实体；墙实体属于房间实体
          layers.each { |layer|  
            if !layer.visible?
                layer.visible = true      
            end         
          }
          wallFace_connected_ents.each{|ent|
            if ent.entityID != current_wallFace.entityID
                ent.visible = true
            end  
          }
          other_connected_wall = WallFace_selObserver.get_other_connected_wall
          if(other_connected_wall !=nil)
            other_connected_wall.visible = true
          end
          dlayer = "wall dimension"
          #删除尺寸
          if House.has_measured_focusedWall == 1 
            if layers["#{dlayer}"] != nil
              layers.remove("#{dlayer}",true) 
            end
            House.has_measured_focusedWall = 0              
          end       
          model.active_view.camera = House.last_camera
          WallFace_selObserver.set_is_hide(0)    
          WallFace_selObserver.set_wallFace(nil)
          WallFace_selObserver.set_current_wall(nil)
          rescue
            puts '发生异常'
          end
        end #if WallFace_selObserver.get_is_hide == 0
      end
    end #def

    #聚焦墙体的时候显示/隐藏尺寸
    def self.wall_dimension(wall)
      if wall != nil #xuyang170826
        House.canClick = 1
        model = Sketchup.active_model
        entities = model.entities
        layers = model.layers
        dlayer = "wall dimension"
        model.active_layer = layers[0]
        puts "隐藏/显示尺寸："+House.has_measured_focusedWall.to_s
        if House.has_measured_focusedWall == 0

          if layers["#{dlayer}"] != nil #xuyang170826
            layers.remove("#{dlayer}",true) 
          end
          
          layer = layers.add(dlayer)
          model.active_layer = layer
          wall_vector = wall.get[3]
          vector_length = 20
          puts wall.get[5].to_s
          vector1 = wall.get[5][0].vector_to(wall.get[5][1])
          offset_vector_1 = wall_vector * vector1
          offset_vector_1.length = vector_length
          vector2 = wall.get[5][2].vector_to(wall.get[5][3])
          offset_vector_2 = vector2 * wall_vector
          offset_vector_2.length = vector_length
          vector3 = wall.get[5][0].vector_to(wall.get[5][2])
          offset_vector_3 = vector3 * wall_vector
          offset_vector_3.length = vector_length
          vector4 = wall.get[5][1].vector_to(wall.get[5][3])
          offset_vector_4 = wall_vector * vector4
          offset_vector_4.length = vector_length

          dim = entities.add_dimension_linear wall.get[5][0],wall.get[5][2],offset_vector_3
          dim.text_position = Sketchup::DimensionLinear::TEXT_CENTERED
          dim.has_aligned_text = true
          dim = entities.add_dimension_linear wall.get[5][0],wall.get[5][1],offset_vector_1
          dim.text_position = Sketchup::DimensionLinear::TEXT_CENTERED
          dim.has_aligned_text = true
          dim = entities.add_dimension_linear wall.get[5][2],wall.get[5][3],offset_vector_2
          dim.text_position = Sketchup::DimensionLinear::TEXT_CENTERED
          dim.has_aligned_text = true
          dim = entities.add_dimension_linear wall.get[5][1],wall.get[5][3],offset_vector_4
          dim.text_position = Sketchup::DimensionLinear::TEXT_CENTERED
          dim.has_aligned_text = true
          if wall.get[5][2].z > wall.get[5][3].z
            z = wall.get[5][2].z
          else
            z = wall.get[5][3].z
          end
          if wall.get[7] != []
            wall.get[7].each{ |e|
              vector_length += 20
              point1 = e.get[0][0]
              point2 = e.get[0][1]
              point3 = [point1.x,point1.y,point2.z]
              point4 = [point2.x,point2.y,point1.z]
              right_line = [wall.get[5][1], Geom::Vector3d.new(0,0,1)]
              dis1 = point1.distance_to_line right_line
              dis2 = point2.distance_to_line right_line
              left_line = [wall.get[5][0], Geom::Vector3d.new(0,0,1)]
              dis3 = point1.distance_to_line left_line
              dis4 = point2.distance_to_line left_line
              if dis1 < dis2
                r_dis = dis1
                if point3.z > point1.z
                  point = point3
                else
                  point = point1
                end
              else
                r_dis = dis2
                if point4.z > point2.z
                  point = point4
                else
                  point = point2
                end
              end
              if r_dis != 0
                offset_vector = Geom::Vector3d.new(0,0,1)
                offset_vector.length = z - point.z + vector_length
                tr_vector = vector1
                tr_vector.length = r_dis
                tr = Geom::Transformation.translation(tr_vector)
                l_point = point
                r_point = point.transform tr
                dim = entities.add_dimension_linear l_point,r_point,offset_vector
                dim.text_position = Sketchup::DimensionLinear::TEXT_CENTERED
                dim.has_aligned_text = true
              end

              if dis1 < dis2
                if point3.z > point1.z
                  point_r = point3
                  point_l = point2
                else
                  point_r = point2
                  point_l = point3
                end
              else
                if point4.z > point2.z
                  point_r = point4
                  point_l = point1
                else
                  point_r = point1
                  point_l = point4
                end
              end
              #puts point_b,point_t
              offset_vector = Geom::Vector3d.new(0,0,1)
              offset_vector.length = z - point.z + vector_length
              dim = entities.add_dimension_linear point_l,point_r,offset_vector
              dim.text_position = Sketchup::DimensionLinear::TEXT_CENTERED
              dim.has_aligned_text = true

              if dis3 < dis4
                l_dis = dis3
                if point3.z > point1.z
                  point = point3
                else
                  point = point1
                end
              else
                l_dis = dis4
                if point4.z > point2.z
                  point = point4
                else
                  point = point2
                end
              end
              if l_dis != 0
                offset_vector = Geom::Vector3d.new(0,0,1)
                offset_vector.length = z - point.z + vector_length
                tr_vector = vector1.reverse
                tr_vector.length = l_dis
                tr = Geom::Transformation.translation(tr_vector)
                l_point = point
                r_point = point.transform tr
                dim = entities.add_dimension_linear l_point,r_point,offset_vector
                dim.text_position = Sketchup::DimensionLinear::TEXT_CENTERED
                dim.has_aligned_text = true
              end

              if point1.z < point2.z
                b_dis = point1.z
                if dis1 < dis2
                  point = point1
                else
                  point = point4
                end
              else
                b_dis = point2.z
                if dis1 < dis2
                  point = point3
                else
                  point = point2
                end
              end
              if b_dis != 0
                offset_vector = offset_vector_4
                offset_vector.length = r_dis + vector_length
                tr_vector = Geom::Vector3d.new(0,0,-1)
                tr_vector.length = point.z
                tr = Geom::Transformation.translation(tr_vector)
                l_point = point
                r_point = point.transform tr
                dim = entities.add_dimension_linear l_point,r_point,offset_vector
                dim.text_position = Sketchup::DimensionLinear::TEXT_CENTERED
                dim.has_aligned_text = true
              end
    
              if point1.z < point2.z
                if dis1 < dis2
                  point_b = point1
                  point_t = point3
                else
                  point_b = point4
                  point_t = point2
                end
              else
                if dis1 < dis2
                  point_b = point3
                  point_t = point1
                else
                  point_b = point2
                  point_t = point4
                end
              end
              offset_vector = offset_vector_4
              offset_vector.length = r_dis + vector_length
              dim = entities.add_dimension_linear point_t,point_b,offset_vector
              dim.text_position = Sketchup::DimensionLinear::TEXT_CENTERED
              dim.has_aligned_text = true

              if point1.z < point2.z
                t_dis = z - point2.z 
                if dis1 < dis2
                  point = point3
                else
                  point = point2
                end
              else
                t_dis = z - point1.z
                if dis1 < dis2
                  point = point1
                else
                  point = point4
                end
              end
              if t_dis != 0
                offset_vector = offset_vector_4
                offset_vector.length = r_dis + vector_length
                tr_vector = Geom::Vector3d.new(0,0,1)
                tr_vector.length = z - point.z
                tr = Geom::Transformation.translation(tr_vector)
                l_point = point.transform tr
                r_point = point
                dim = entities.add_dimension_linear l_point,r_point,offset_vector
                dim.text_position = Sketchup::DimensionLinear::TEXT_CENTERED
                dim.has_aligned_text = true
              end
            }
          end
          if wall.get[8] != []
            wall.get[8].each{ |e|
              vector_length += 20
              point1 = e.get[0][0]
              point2 = e.get[0][1]
              point3 = [point1.x,point1.y,point2.z]
              point4 = [point2.x,point2.y,point1.z]
              right_line = [wall.get[5][1], Geom::Vector3d.new(0,0,1)]
              dis1 = point1.distance_to_line right_line
              dis2 = point2.distance_to_line right_line
              left_line = [wall.get[5][0], Geom::Vector3d.new(0,0,1)]
              dis3 = point1.distance_to_line left_line
              dis4 = point2.distance_to_line left_line

              if dis1 < dis2
                r_dis = dis1
                if point3.z > point1.z
                  point = point3
                else
                  point = point1
                end
              else
                r_dis = dis2
                if point4.z > point2.z
                  point = point4
                else
                  point = point2
                end
              end
              if r_dis != 0
                offset_vector = Geom::Vector3d.new(0,0,1)
                offset_vector.length = z - point.z + vector_length
                tr_vector = vector1
                tr_vector.length = r_dis
                tr = Geom::Transformation.translation(tr_vector)
                l_point = point
                r_point = point.transform tr
                dim = entities.add_dimension_linear l_point,r_point,offset_vector
                dim.text_position = Sketchup::DimensionLinear::TEXT_CENTERED
                dim.has_aligned_text = true
              end

              if dis1 < dis2
                if point3.z > point1.z
                  point_r = point3
                  point_l = point2
                else
                  point_r = point2
                  point_l = point3
                end
              else
                if point4.z > point2.z
                  point_r = point4
                  point_l = point1
                else
                  point_r = point1
                  point_l = point4
                end
              end
              #puts point_b,point_t
              offset_vector = Geom::Vector3d.new(0,0,1)
              offset_vector.length = z - point.z + vector_length
              dim = entities.add_dimension_linear point_l,point_r,offset_vector
              dim.text_position = Sketchup::DimensionLinear::TEXT_CENTERED
              dim.has_aligned_text = true
   
              if dis3 < dis4
                l_dis = dis3
                if point3.z > point1.z
                  point = point3
                else
                  point = point1
                end
              else
                l_dis = dis4
                if point4.z > point2.z
                  point = point4
                else
                  point = point2
                end
              end
              if l_dis != 0
                offset_vector = Geom::Vector3d.new(0,0,1)
                offset_vector.length = z - point.z + vector_length
                tr_vector = vector1.reverse
                tr_vector.length = l_dis
                tr = Geom::Transformation.translation(tr_vector)
                l_point = point
                r_point = point.transform tr
                dim = entities.add_dimension_linear l_point,r_point,offset_vector
                dim.text_position = Sketchup::DimensionLinear::TEXT_CENTERED
                dim.has_aligned_text = true
              end

              if point1.z < point2.z
                b_dis = point1.z
                if dis1 < dis2
                  point = point1
                else
                  point = point4
                end
              else
                b_dis = point2.z
                if dis1 < dis2
                  point = point3
                else
                  point = point2
                end
              end
              if b_dis != 0
                offset_vector = offset_vector_4
                offset_vector.length = r_dis + vector_length
                tr_vector = Geom::Vector3d.new(0,0,-1)
                tr_vector.length = point.z
                tr = Geom::Transformation.translation(tr_vector)
                l_point = point
                r_point = point.transform tr
                dim = entities.add_dimension_linear l_point,r_point,offset_vector
                dim.text_position = Sketchup::DimensionLinear::TEXT_CENTERED
                dim.has_aligned_text = true
              end

              if point1.z < point2.z
                if dis1 < dis2
                  point_b = point1
                  point_t = point3
                else
                  point_b = point4
                  point_t = point2
                end
              else
                if dis1 < dis2
                  point_b = point3
                  point_t = point1
                else
                  point_b = point2
                  point_t = point4
                end
              end
              offset_vector = offset_vector_4
              offset_vector.length = r_dis + vector_length
              dim = entities.add_dimension_linear point_t,point_b,offset_vector
              dim.text_position = Sketchup::DimensionLinear::TEXT_CENTERED
              dim.has_aligned_text = true

              if point1.z < point2.z
                t_dis = z - point2.z 
                if dis1 < dis2
                  point = point3
                else
                  point = point2
                end
              else
                t_dis = z - point1.z
                if dis1 < dis2
                  point = point1
                else
                  point = point4
                end
              end
              if t_dis != 0
                offset_vector = offset_vector_4
                offset_vector.length = r_dis + vector_length
                tr_vector = Geom::Vector3d.new(0,0,1)
                tr_vector.length = z - point.z
                tr = Geom::Transformation.translation(tr_vector)
                l_point = point.transform tr
                r_point = point
                dim = entities.add_dimension_linear l_point,r_point,offset_vector
                dim.text_position = Sketchup::DimensionLinear::TEXT_CENTERED
                dim.has_aligned_text = true
              end
            }  
          end
          House.has_measured_focusedWall = 1
        elsif House.has_measured_focusedWall == 1 
           puts '隐藏尺寸'
            if layers["#{dlayer}"] != nil
              layers.remove("#{dlayer}",true) 
            end
            House.has_measured_focusedWall = 0              
        end  
         puts "隐藏/显示尺寸："+House.has_measured_focusedWall.to_s        
      else
        UI.messagebox("没有墙面被聚焦,请选择一个墙面并聚焦！")
      end
    end #wall_dimension
  end
end