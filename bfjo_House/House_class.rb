module BFJO
  module House
    class Set_origin_tool
      def initialize
        @input
        @origin
      end

      def activate
        @input = Sketchup::InputPoint.new
      end

      def onLButtonDown(flags, x, y, view)
        @input.pick view,x,y
        pos = @input.position
        @origin = Geom::Point3d.new(pos.x,pos.y,0)
        if @origin != nil
          content = '房间原点选择完毕。坐标('+pos.x.to_mm.round(2).to_s+','+pos.y.to_mm.round(2).to_s+','+'0.00'+')'
          message = "'#{content}'"
          # House.Web.execute_script("showMessage("+"#{message}"+")")
          #创建房间成功后显示接下来的操作按钮
          House.Web.execute_script("show_hidden_btn("+"#{message}"+","+"1"+")")
          House.Web.execute_script("$('#set_origin_info').hide()")
          House.Web.execute_script("$('#room_origin_cover_layer').hide()")
          House.origin = @origin
          House.origin_tr = Geom::Transformation.new(@origin)
          House.model.tools.remove_observer(House.set_origin_tool_observer)
          House.model.select_tool(nil)
        end
        #puts pos
      end

      def get_origin
        return @origin
      end
    end

    class Redraw_set_origin_tool
      def initialize
        @input
        @origin
      end

      def activate
        @input = Sketchup::InputPoint.new
      end

      def onLButtonDown(flags, x, y, view)
        @input.pick view,x,y
        pos = @input.position
        @origin = Geom::Point3d.new(pos.x,pos.y,0)
        if @origin != nil
          content = '房间原点选择完毕。坐标('+pos.x.to_mm.round(2).to_s+','+pos.y.to_mm.round(2).to_s+','+'0.00'+')'
          message = "'#{content}'"
          House.Web.execute_script("showMessage("+"#{message}"+")")
          #创建房间成功后显示接下来的操作按钮
          # House.Web.execute_script("show_hidden_btn("+"#{message}"+","+"1"+")")
          # House.Web.execute_script("$('#set_origin_info').hide()")

          # House.room.set_origin(@origin)
          House.origin_tr = Geom::Transformation.new(@origin)
          House.model.tools.remove_observer(House.set_origin_tool_observer)
          House.model.select_tool(nil)
        end
        #puts pos
      end

      def get_origin
        return @origin
      end
    end

    class Set_origin_tool_Observer < Sketchup::ToolsObserver
      def onActiveToolChanged(tools, tool_name, tool_id)
        #puts tool_name
        if House.origin_tr == nil && tool_name != "RubyTool"
          result = UI.messagebox("尚未选择房间原点，是否继续选择？（否则房间原点为[0,0,0]。）",MB_YESNO)
          if result == IDYES
            se_tool = Set_origin_tool.new
            House.model.select_tool se_tool
          else
            # House.room.set_origin([0,0,0])
            House.origin = [0,0,0]
            House.origin_tr = Geom::Transformation.new([0,0,0])
            House.model.tools.remove_observer(House.set_origin_tool_observer)
          end
        end
      end
    end

    #当选中某个墙面的时候
    # class WallFace_selObserver < Sketchup::SelectionObserver
    #   @@is_hide = 0
    #   @@current_show_wall = nil
    #   @@wallFace = nil
    #   ##当墙有角柱的时候，该变量表示柱子所连接的另一面墙
    #   @@other_connected_wall = nil
    #   def self.get_current_wall
    #       return @@current_show_wall
    #   end
    #   def self.set_current_wall(value)
    #       @@current_show_wall =  value
    #   end
    #   def self.get_wallFace
    #       return @@wallFace
    #   end
    #   def self.set_wallFace(value)
    #       @@wallFace = value
    #   end
    #   def self.get_is_hide
    #       return @@is_hide
    #   end
    #   def self.set_is_hide(value)
    #       @@is_hide = value
    #   end

    #   def self.get_other_connected_wall
    #       return @@other_connected_wall
    #   end
    #   def self.set_other_connected_wall(value)
    #       @@other_connected_wall = value
    #   end

    #   def onSelectionBulkChange(selection)
    #     if selection[0].is_a? Sketchup::Face
    #        @@wallFace = selection[0]
    #     end
    #     if selection[0].is_a? Sketchup::Group
    #         if House.room != nil
    #           walls = House.room.get[1]
    #           walls.each{ |wall|
    #           #puts "wallid:#{wall.get[4][0].entityID}"
    #           if wall.get[4][0].entityID == selection[0].entityID
    #             House.cwall = wall
    #           end
    #         }
    #         end
    #     end
    #   end
    # end

    class Undo_entity_observer < Sketchup::EntitiesObserver
      def onElementAdded(entities, entity)
        if !entity.deleted?
          if entity.get_attribute("house_mobject","type") == "wall_line"
            puts "undo:::onElementAdded: #{entity}"
            House.last_entity.push(entity)
          end
          # puts entity.typename
          # puts entity.get_attribute "house_mobject","type"
          if entity.typename == "Group" && entity.get_attribute("house_mobject","type") == "wall"
            puts "undo::group::onElementAdded: #{entity}"
            House.last_entity.push(entity)
          end
        end
      end
    end

    class Room_deleted_observer < Sketchup::EntityObserver 
      def onEraseEntity(entity)
        puts '清除'
        deleted_rooms_name = []
        deleted_rooms = []
        if House.house.get["rooms"].length !=0
          House.house.get["rooms"].each{ |room_name,room|  
          if room.get["su_model"].get["entity"].deleted?
           
            #注：变量要记得加两个点
            House.Web.execute_script("delete_room_from_ruby("+"'#{room_name}'"+")")
            deleted_rooms.push(room)
          end
        }
        end

        if deleted_rooms != [] && deleted_rooms_name != []
          #从数据中移除room
          deleted_rooms.each{|deleted_room|
              House.house.get["rooms"].delete(deleted_room)
          }
        end
      end
    end

    class MObject
      def initialize
        @id
        @points = []
        @mdimension = MDimension.new
        @su_model = SU_model.new
        @used_to_return = {"id" => @id,"points" => @points,"su_model" => @su_model,"mdimension"=>@mdimension}
      end

      def set_point(i,point)
        @points[i] = Geom::Point3d.new(point.x,point.y,point.z)
      end

      def set_id(id)
        @id = id
        @used_to_return["id"] = @id
      end

      def get
        return @used_to_return
      end
    end

    class SU_model
      def initialize
        @entity
        @text
        @entOb
        @used_to_return = {"entity" => @entity,"entOb" => @entOb,"text" => @text}
      end

      def set_entity(entity)
        @entity = entity
        @used_to_return["entity"] = @entity
      end

      def set_text(text)
        @text = text
        @used_to_return["text"] = @text
      end

      def set_entob(entob)
        @entOb = entob
        @entity.add_observer @entOb
        @used_to_return["entOb"] = @entOb
      end

      def get
        return @used_to_return
      end

      def draw(object)
        layers = House.model.layers
        materials = House.model.materials
        case object.class.to_s
        when "BFJO::House::Wall"
          layer_name = House.room.get["id"] + object.get["id"]
          layers.add("#{layer_name}")
          House.model.active_layer = layers["#{layer_name}"]
          inner_points = object.get["inner_points"]
          outter_points = object.get["outter_points"]
          point1 = inner_points[0]
          point2 = inner_points[1]
          point3 = outter_points[1]
          point4 = outter_points[0]
          point5 = inner_points[2]
          point6 = inner_points[3]
          point7 = outter_points[3]
          point8 = outter_points[2]

          #设置墙的材质
          wall_material1 = materials["material1"]
          wall_material2 = materials["material2"]

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
          
          wall_group = House.entities.add_group inner_wall.all_connected
          wall_group.set_attribute "house_mobject","type","wall"
          wall_group.set_attribute "house_mobject","id",object.get["id"]
          set_entity(wall_group)
          wall_ent_ob = Wall_ent_ob.new
          set_entob(wall_ent_ob)
          mx = ((point1.x + point2.x) / 2 + (point4.x + point3.x) / 2) / 2
          my = ((point1.y + point2.y) / 2 + (point4.y + point3.y) / 2) / 2
          tpoint = [mx,my,point5.z + 10]
          layers.add("标签")
          House.model.active_layer = layers["标签"]
          text = House.entities.add_text layer_name,tpoint

          offset = object.get["normal_vector"].reverse
          offset.length = 24
          object.get["mdimension"].create_dim(point1,point2,offset,object.get["id"],"redraw_width",1)
          set_text(text)
          # House.entity_group.push(text)
        when "BFJO::House::Skirtingline"
          begin
            House.model.start_operation('踢脚线', true)
            walls = House.room.get["mobjects"]["BFJO::House::Wall"]
            layer_name = House.room.get["id"] + object.get["id"]
            layers.add(layer_name)
            layer = layers[layer_name]
            House.model.active_layer = layer
            woutter_points = []
            winner_points = []
            inner_face = []
            trs = []
            walls.each{ |wall|  
              #取内墙面2点
              outter_point_1 = wall.get["inner_points"][0]
              outter_point_2 = wall.get["inner_points"][1]
              vec1 = wall.get["normal_vector"].reverse
              vec1.length = object.get["depth"]
              tr1 = Geom::Transformation.translation(vec1)
              trs.push(tr1)
              woutter_points.push(outter_point_1)
              inner_point_1 = outter_point_1.transform tr1
              inner_point_2 = outter_point_2.transform tr1
              winner_points.push(inner_point_1)
              winner_points.push(inner_point_2)
              plane = [wall.get["inner_points"][0],wall.get["normal_vector"]]
              inner_face.push(plane)
            }

            columns = House.room.get["mobjects"]["BFJO::House::Column"]
            column_points = {}
            inner_column_points = {}
            if columns != nil && columns != []
              columns.each{ |column|
                if column.get["type"] == "wall_mid_column"
                  p1 = column.get["points"][2]
                  p2 = column.get["points"][3]
                  points = [p1,p2]
                  mi = Geometry::find_belong_wall(points,inner_face)

                  if column_points["#{mi}"] == nil
                    column_points["#{mi}"] = []
                  end
                  p3 = column.get["points"][1]
                  p4 = column.get["points"][0]
                  v1 = p2 - p1
                  inner_points = walls[mi].get["inner_points"]
                  vp1 = Geom::Point3d.new(inner_points[1].x,inner_points[1].y,inner_points[1].z)
                  vp2 = Geom::Point3d.new(inner_points[0].x,inner_points[0].y,inner_points[0].z)
                  v2 = vp1 - vp2
                  if v2.angle_between(v1) > 0.01
                    temp = p1
                    p1 = p2
                    p2 = temp
                    temp = p3
                    p3 = p4
                    p4 = temp
                  end
                  column_points["#{mi}"].push(p1)
                  column_points["#{mi}"].push(p3)
                  column_points["#{mi}"].push(p4)
                  column_points["#{mi}"].push(p2)

                  if inner_column_points["#{mi}"] == nil
                    inner_column_points["#{mi}"] = []
                  end
                  v1 = v2.reverse
                  v1.length = object.get["depth"]
                  tr1 = Geom::Transformation.translation(v1)
                  inner_p1 = p1.transform tr1
                  inner_p2 = p3.transform tr1
                  v2 = p3 - p1
                  v2 = Geom::Vector3d.new(v2.x,v2.y,v2.z)
                  v2.length = object.get["depth"]
                  tr2 = Geom::Transformation.translation(v2)
                  inner_p3 = p3.transform tr2
                  inner_p4 = p4.transform tr2
                  inner_p7 = p2.transform tr2
                  inner_p8 = winner_points[2 * mi + 1]
                  v3 = v1.reverse
                  v3.length = object.get["depth"]
                  tr3 = Geom::Transformation.translation(v3)
                  inner_p5 = p4.transform tr3
                  inner_p6 = p2.transform tr3

                  inner_column_points["#{mi}"].push(inner_p1)
                  inner_column_points["#{mi}"].push(inner_p2)
                  inner_column_points["#{mi}"].push(inner_p3)
                  inner_column_points["#{mi}"].push(inner_p4)
                  inner_column_points["#{mi}"].push(inner_p5)
                  inner_column_points["#{mi}"].push(inner_p6)
                  inner_column_points["#{mi}"].push(inner_p7)
                  inner_column_points["#{mi}"].push(inner_p8)
                elsif column.get["type"] == "corner_column"
                  p1 = column.get["points"][1]
                  p2 = column.get["points"][2]
                  points = [p1,p2]
                  mi = Geometry::find_belong_wall(points,inner_face)

                  if column_points["#{mi}"] == nil
                    column_points["#{mi}"] = []
                  end
                  if column_points["#{mi + 1}"] == nil
                    column_points["#{mi + 1}"] = []
                  end
                  column_points["#{mi}"].push(column.get["points"][1])
                  column_points["#{mi}"].push(column.get["points"][0])
                  woutter_points[mi + 1] = column.get["points"][3]

                  v1 = column.get["points"][0] - column.get["points"][3]
                  v1 = Geom::Vector3d.new(v1.x,v1.y,v1.z)
                  v1.length = object.get["depth"]
                  tr1 = Geom::Transformation.translation(v1)
                  inner_p1 = column.get["points"][1].transform tr1
                  inner_p2 = column.get["points"][0].transform tr1
                  v2 = column.get["points"][0] - column.get["points"][1]
                  v2 = Geom::Vector3d.new(v2.x,v2.y,v2.z)
                  v2.length = object.get["depth"]
                  tr2 = Geom::Transformation.translation(v2)
                  inner_p3 = column.get["points"][0].transform tr2
                  inner_p4 = column.get["points"][3].transform tr2

                  if inner_column_points["#{mi}"] == nil
                    inner_column_points["#{mi}"] = []
                  end
                  inner_column_points["#{mi}"].push(inner_p1)
                  inner_column_points["#{mi}"].push(inner_p2)
                  inner_column_points["#{mi}"].push(inner_p3)
                  inner_column_points["#{mi}"].push(inner_p4)
                end
              }
            end

            door_groups = []
            doors = House.room.get["mobjects"]["BFJO::House::Door"]
            if doors != nil && doors != []
              doors.each{ |door|  
                door_point_1 = [door.get["points"][0].x,door.get["points"][0].y,door.get["points"][0].z]
                door_point_2 = [door.get["points"][1].x,door.get["points"][1].y,door.get["points"][1].z]
                if door_point_1.z < door_point_2.z
                  door_height = door_point_1.z
                  door_point_2.z = door_point_1.z
                else
                  door_height = door_point_2.z
                  door_point_1.z = door_point_2.z
                end
                s = door.get["wid"].to_i - 1
                door_point_3 = door_point_2.transform trs[s]
                door_point_4 = door_point_1.transform trs[s]
                door_face = House.entities.add_face door_point_1,door_point_2,door_point_3,door_point_4
                door_face.reverse!
                door_face.pushpull object.get["height"] - door_height
                door_group = House.entities.add_group door_face.all_connected
                door_groups.push(door_group)
              }
            end

            outter_points = []
            inner_points = []
            for i in 0..(walls.size - 1)
              outter_points.push(woutter_points[i])
              puts column_points["#{i}"]
              if column_points["#{i}"] != nil

                column_points["#{i}"].each{ |cp|  
                  outter_points.push(cp)
                }
              end
              puts inner_column_points["#{i}"]
              inner_points.push(winner_points[2 * i])
              inner_points.push(winner_points[2 * i + 1])
              if inner_column_points["#{i}"] != nil
                inner_column_points["#{i}"].each{ |cp|  
                  inner_points.push(cp)
                }
              end
            end

            calculated_inner_points = []
            for i in 0..(inner_points.size - 1)
              if i % 2 != 0
                point1 = inner_points[i]
                point2 = inner_points[i - 1]
                if i == 1
                  point3 = inner_points[inner_points.size - 2]
                  point4 = inner_points[inner_points.size - 1]
                else
                  point3 = inner_points[i - 3]
                  point4 = inner_points[i - 2]
                end
                calculated_inner_point = Geometry::intersect_between_lines(point1,point2,point3,point4)
                calculated_inner_points.push(calculated_inner_point)
              end
              i += 1
            end
            bottom_face = House.entities.add_face outter_points
            bottom_face.reverse!
            bottom_face.pushpull object.get["height"]
            group1 = House.entities.add_group bottom_face.all_connected
            bottom_face_2 = House.entities.add_face calculated_inner_points
            bottom_face_2.reverse!
            bottom_face_2.pushpull object.get["height"]
            group2 = House.entities.add_group bottom_face_2.all_connected
            skirtingline_group = group2.subtract(group1)
            if door_groups != []
              door_groups.each{ |door|  
                skirtingline_group = door.subtract(skirtingline_group)
              }
            end
            skirtingline_group.set_attribute "house_mobject","type","skirtingline"
            skirtingline_group.set_attribute "house_mobject","id",object.get["id"]
            
            set_entity(skirtingline_group)
            skirtingline_ent_ob = Skirtingline_ent_ob.new
            set_entob(skirtingline_ent_ob)
            
            House.model.commit_operation
            House.entity_group.push(skirtingline_group)
          rescue 
            raise "draw_skirtingline_err"
          end
        when "BFJO::House::Tripoint_pipe"
          begin
            House.model.start_operation('三点水管', true)
            layer_name = House.room.get["id"] + object.get["id"]
            layers.add(layer_name)
            House.model.active_layer = layers[layer_name]

            circle = House.entities.add_circle object.get["points"][0],[0,0,-1],object.get["radius"],72
            bottom_face = House.entities.add_face circle
            bottom_face.reverse!
            bottom_face.pushpull object.get["height"]
            pipe = House.entities.add_group bottom_face.all_connected
            pipe.set_attribute "house_mobject","type","tripoint_pipe"
            pipe.set_attribute "house_mobject","id",object.get["id"]
            set_entity(pipe)
            tripoint_pipe_ent_ob = Tripoint_pipe_ent_ob.new
            set_entob(tripoint_pipe_ent_ob)

            House.entity_group.push(pipe)
            House.model.commit_operation
          rescue
            raise "draw_tripoint_pipe_err"
          end
        when "BFJO::House::Water_pipe"
          begin
            House.model.start_operation('水管', true)
            layer_name = House.room.get["id"] + object.get["id"]
            layers.add(layer_name)
            House.model.active_layer = layers[layer_name]
            circle = House.entities.add_circle object.get["points"][0],object.get["normal"],object.get["radius"],72
            bottom_face = House.entities.add_face circle
            bottom_face_vector = bottom_face.normal.normalize
            if bottom_face_vector == object.get["normal"].normalize
              bottom_face.reverse!
            end
            bottom_face.pushpull object.get["height"]
            pipe_group = House.entities.add_group bottom_face.all_connected
            pipe_group.set_attribute "house_mobject","type","water_pipe"
            pipe_group.set_attribute "house_mobject","id",object.get["id"]
            radius_text = (object.get["radius"] * 2).to_mm.round.to_s + ".mm"
            House.entities.add_text radius_text.to_s,object.get["points"][0]
            set_entity(pipe_group)
            water_pipe_ent_ob = Water_pipe_ent_ob.new
            set_entob(water_pipe_ent_ob)

            House.model.commit_operation
            House.entity_group.push(pipe_group)
            House.entity_group.push(radius_text)
          rescue
            raise "draw_water_pipe_err"
          end
        when "BFJO::House::Door"
          begin
            House.model.start_operation('门', true)
            a_entities = Sketchup.active_model.active_entities
            walls = House.room.get["mobjects"]["BFJO::House::Wall"]
            m = object.get["wid"].to_i - 1
            wall = walls[m]
            wall_layer = House.room.get["id"] + wall.get["id"]
            layer = layers[wall_layer]
            House.model.active_layer = layer
            #门厚度与墙相同
            door_thickness = wall.get["thickness"]
            door_point1 = object.get["points"][0]
            door_point2 = object.get["points"][1]
            door_point3 = [door_point1.x,door_point1.y,door_point2.z]
            door_point4 = [door_point2.x,door_point2.y,door_point1.z]
            # puts door_point1,door_point4,door_point2,door_point3
            door_face = a_entities.add_face door_point1,door_point4,door_point2,door_point3
            door_vector = door_face.normal
            door_vector.normalize!
            wall_vector = wall.get["normal_vector"]
            wall_vector.normalize!
            if door_vector.angle_between(wall_vector) > 1.57
              door_face.reverse!
            end
            door_face.pushpull door_thickness
            door_entity = a_entities.add_group door_face.all_connected
            wall_entity = wall.get["su_model"].get["entity"]
            result = door_entity.subtract(wall_entity)
            result.set_attribute "house_mobject","id",wall.get["id"]
            result.set_attribute "house_mobject","type","wall"
            wall.get["su_model"].set_entity(result)
            if object.get["id"] != nil
              object.create_dim
            end
            House.model.commit_operation
          rescue
            raise "draw_door_err"
          end
        when "BFJO::House::Window"
          begin
            a_entities = Sketchup.active_model.active_entities
            House.model.start_operation('窗', true)
            if object.get["type"] == "normal_window" || object.get["type"] == "bay_window"
              walls = House.room.get["mobjects"]["BFJO::House::Wall"]
              m = object.get["wid"].to_i - 1
              wall = walls[m]
              
              wall_layer = House.room.get["id"] + wall.get["id"]
              layer = layers[wall_layer]
              House.model.active_layer = layer

              wall_thickness_n = wall.get["thickness"]
              i_plane = [wall.get["inner_points"][0],wall.get["normal_vector"]]

              point1 = object.get["points"][0]
              point3 = object.get["points"][1]
              point2 = [point1.x,point1.y,point3.z]
              point4 = [point3.x,point3.y,point1.z]
              window_face = a_entities.add_face point1,point2,point3,point4
              window_face.reverse!
              
              window_vector = window_face.normal
              window_vector.normalize!
              wall_vector = wall.get["normal_vector"]
              wall_vector.normalize!
              if window_vector.angle_between(wall_vector) > 1.57
                window_face.reverse!
              end
              # wall_thickness_n += 2.mm
              window_face.pushpull wall_thickness_n
              window_entity = a_entities.add_group window_face.all_connected

              wall_entity = wall.get["su_model"].get["entity"]
              result = window_entity.subtract(wall_entity)
              result.set_attribute "house_mobject","id",wall.get["id"]
              result.set_attribute "house_mobject","type","wall"
              # text = wall.get[4][1]
              wall.get["su_model"].set_entity(result)
              if object.get["type"] == "bay_window"
                dis = object.get["points"][2].distance_to_plane i_plane
                if dis > wall_thickness_n
                  differ = dis - wall_thickness_n
                  window_face = a_entities.add_face point1,point2,point3,point4
                  window_face.reverse!
                  window_face.pushpull differ
                  window_entity = a_entities.add_group window_face.all_connected
                  vec = wall.get["normal_vector"]
                  vec.length = wall_thickness_n
                  tr = Geom::Transformation.translation(vec)
                  window_entity.transform! tr
                  window_material = House.model.materials.add('window_material')
                  window_material.alpha = 0
                  window_entity.material = window_material
                  result.set_attribute "house_mobject","type","window"
                  result.set_attribute "house_mobject","id",object.get["id"]
                  object.get["su_model"].set_entity(window_entity)
                  House.entity_group.push(window_entity)
                end
              end
            elsif object.get["type"] == "L_bay_window"
              walls = House.room.get["mobjects"]["BFJO::House::Wall"]
              id = object.get["wid"].split(",")
              wall1 = walls[id[0].to_i - 1]
              wall2 = walls[id[1].to_i - 1]
              wall_thickness_1 = wall1.get["thickness"]
              wall_thickness_2 = wall2.get["thickness"]
              wall_thickness = [wall_thickness_1,wall_thickness_2]
              plane_1 = [wall1.get["inner_points"][0],wall1.get["normal_vector"]]
              plane_2 = [wall2.get["inner_points"][0],wall2.get["normal_vector"]]
              dis1 = object.get["points"][0].distance_to_plane plane_1
              dis2 = object.get["points"][1].distance_to_plane plane_2
              window_material = House.model.materials.add('L_bay_window_material')
              window_material.alpha = 0
              base_vec = Geom::Vector3d.new(0, 0, -1)
              height = object.get["points"][0].distance object.get["points"][2]
              #将第一面墙挖空
              wall_layer = House.room.get["id"] + wall1.get["id"]
              House.model.active_layer = layers[wall_layer]
              plane = [wall1.get["outter_points"][0],wall1.get["normal_vector"]]  #外墙面
              point1 = object.get["points"][2].project_to_plane plane
              point2 = object.get["points"][2].project_to_plane plane_1
              point3 = wall1.get["outter_points"][1].project_to_plane plane_1
              point3.z = point1.z
              point4 = [wall1.get["outter_points"][1].x,wall1.get["outter_points"][1].y,wall1.get["outter_points"][1].z]
              point4.z = point1.z
              face1 = a_entities.add_face point1,point2,point3,point4
              if face1.normal.angle_between(base_vec) < 0.1
                face1 .reverse!
              end
              face1.pushpull height
              entity1 = a_entities.add_group face1.all_connected
              wall_entity = wall1.get["su_model"].get["entity"]
              result = entity1.subtract(wall_entity)
              result.set_attribute "house_mobject","type","wall"
              result.set_attribute "house_mobject","id",wall1.get["id"]
              wall1.get["su_model"].set_entity(result)
              #将第二面墙挖空
              wall_layer = House.room.get["id"] + wall2.get["id"]
              House.model.active_layer = layers[wall_layer]
              plane = [wall2.get["outter_points"][0],wall2.get["normal_vector"]]  #外墙面
              point1 = object.get["points"][1].project_to_plane plane
              point2 = object.get["points"][1].project_to_plane plane_2
              point3 = wall2.get["outter_points"][0].project_to_plane plane_2
              point3.z = point1.z
              point4 = [wall2.get["outter_points"][0].x,wall2.get["outter_points"][0].y,wall2.get["outter_points"][0].z]
              point4.z = point1.z
              face2 = a_entities.add_face point1,point2,point3,point4
              if face2.normal.angle_between(base_vec) < 0.1
                face2 .reverse!
              end
              face2.pushpull height
              entity2 = a_entities.add_group face2.all_connected
              wall_entity = wall2.get["su_model"].get["entity"]
              result = entity2.subtract(wall_entity)
              result.set_attribute "house_mobject","type","wall"
              result.set_attribute "house_mobject","id",wall2.get["id"]
              # text = wall2.get[4][1]
              wall2.get["su_model"].set_entity(result)
              layers.add(House.room.get["id"] + object.get["id"])
              layer = layers[House.room.get["id"] + object.get["id"]]
              House.model.active_layer = layer
              
              draw_points = []
              if dis2 <= wall_thickness_2
                point = object.get["points"][1] #外轮廓右下角点
                point1 = point.project_to_plane plane_2 #内轮廓右下角点
                draw_points.push(point1)
                draw_points.push(point)
              else
                point = object.get["points"][1] #外轮廓右下角点
                plane = [wall2.get["outter_points"][0],wall2.get["normal_vector"]]  #外墙面
                point1 = point.project_to_plane plane #内轮廓右下角点
                draw_points.push(point1)
                draw_points.push(point)
              end
              draw_points.push(object.get["points"][3])  #外轮廓交点
              if dis1 <= wall_thickness_1
                point = object.get["points"][2] #外轮廓左下角点
                draw_points.push(point)
                point2 = point.project_to_plane plane_1 #内轮廓左下角点
                draw_points.push(point2)
              else
                point = object.get["points"][2] #外轮廓左下角点
                draw_points.push(point)
                plane = [wall1.get["outter_points"][0],wall1.get["normal_vector"]]  #外墙面
                point2 = point.project_to_plane plane #内轮廓左下角点
                draw_points.push(point2)
              end
              #求内轮廓交点
              wall_edge_vec_1 = wall1.get["inner_points"][0].vector_to wall1.get["inner_points"][1]
              wall_edge_vec_2 = wall2.get["inner_points"][1].vector_to wall2.get["inner_points"][0]
              wall_edge_vec_1.length = 1
              wall_edge_vec_2.length = 1
              tr1 = Geom::Transformation.translation(wall_edge_vec_1)
              tr2 = Geom::Transformation.translation(wall_edge_vec_2)
              point3 = point2.transform tr1
              point4 = point1.transform tr2
              intersect_point = Geometry::intersect_between_lines(point2,point3,point1,point4)
              draw_points.push(intersect_point)
              bottom_face = a_entities.add_face draw_points
              if bottom_face.normal.angle_between(base_vec) < 0.1
                bottom_face.reverse!
              end
              bottom_face.pushpull height
              # window_entity = a_entities.add_group bottom_face.all_connected
              # window_entity.material = window_material
              bottom_face.all_connected.each{ |e|  
                e.material = window_material
                if e.typename == "Face"
                  e.back_material = window_material
                end
              }

              draw_points_1 = []
              draw_points.each{ |p|  
                p1 = Geom::Point3d.new(p.x,p.y,p.z - 1.mm)
                draw_points_1.push(p1)
              }
              bottom_face_s = a_entities.add_face draw_points_1
              vector = Geom::Vector3d.new(0,0,1)
              ceiling = [walls[0].get["inner_points"][2],House.room.get["ceiling_vector"]]
              s1 = draw_points[0].distance_to_plane ceiling
              s2 = draw_points[0].z
              if bottom_face_s.normal.angle_between(base_vec) >= 0.1
                bottom_face_s.reverse!
              end
              bottom_face_s.pushpull s2

              draw_points_2 = []
              vector.length = s1
              b2t_tr = Geom::Transformation.translation(vector)
              # top_face_s = bottom_face_s.transform b2t_tr
              draw_points.each{ |p|  
                draw_points_2.push(p.transform b2t_tr)
              }
              top_face_s = a_entities.add_face draw_points_2
              if top_face_s.normal.angle_between(base_vec) >= 0.1
                top_face_s.reverse!
              end
              top_face_s.pushpull (s1 - height)

              window_entity = House.entities.add_group top_face_s.all_connected,bottom_face_s.all_connected

              object.get["su_model"].set_entity(window_entity)
              House.entity_group.push(window_entity)
            end
            object.create_dim
            House.model.commit_operation
          rescue
            raise "draw_window_err"
          end
        when "BFJO::House::Column"
          begin
            House.model.start_operation('柱', true)
            layer_name = House.room.get["id"] + object.get["id"]
            layers.add(layer_name)
            House.model.active_layer = layers[layer_name]
            
            column = object
            puts column.get['points'][0].class
            bottom_face = House.entities.add_face column.get['points'][0],column.get['points'][1],column.get['points'][2],column.get['points'][3]
            base_vec = Geom::Vector3d.new(0, 0, 1)
            if bottom_face.normal.angle_between(base_vec) < 0.1
              bottom_face.reverse!
            end
            House.entities.add_face column.get['points'][0],column.get['points'][4],column.get['points'][5],column.get['points'][1]
            House.entities.add_face column.get['points'][4],column.get['points'][5],column.get['points'][6],column.get['points'][7]
            House.entities.add_face column.get['points'][1],column.get['points'][2],column.get['points'][6],column.get['points'][5]
            House.entities.add_face column.get['points'][2],column.get['points'][3],column.get['points'][7],column.get['points'][6]
            House.entities.add_face column.get['points'][0],column.get['points'][3],column.get['points'][7],column.get['points'][4]
            column_group = House.entities.add_group bottom_face.all_connected
            column_group.set_attribute "house_mobject","type","column"
            column_group.set_attribute "house_mobject","id",object.get["id"]
            set_entity(column_group)
            column_ent_ob = Column_ent_ob.new
            set_entob(column_ent_ob)
            
            object.create_dim
            House.model.commit_operation
            House.entity_group.push(column_group)
          rescue
            raise "draw_column_err"
          end
        when "BFJO::House::Girder"
          begin
            House.model.start_operation('梁', true)
            girder = object
            layer_name = House.room.get["id"] + object.get["id"]
            layers.add(layer_name)
            House.model.active_layer = layers[layer_name]
            
            p1 = girder.get['points'][0]
            p2 = girder.get['points'][1]
            p3 = girder.get['points'][2]
            p4 = girder.get['points'][3]
            p5 = girder.get['points'][4]
            p6 = girder.get['points'][5]
            p7 = girder.get['points'][6]
            p8 = girder.get['points'][7]
            bottom_face = House.entities.add_face p1,p2,p6,p5
            base_vec = Geom::Vector3d.new(0, 0, 1)
            if bottom_face.normal.angle_between(base_vec) < 0.1
              bottom_face.reverse!
            end
            House.entities.add_face p1,p4,p8,p5
            House.entities.add_face p4,p3,p7,p8
            House.entities.add_face p3,p2,p6,p7
            House.entities.add_face p1,p2,p3,p4
            House.entities.add_face p5,p6,p7,p8
            girder_group = House.entities.add_group bottom_face.all_connected
            girder_group.set_attribute "house_mobject","type","girder"
            girder_group.set_attribute "house_mobject","id",object.get["id"]
            
            set_entity(girder_group)
            girder_ent_ob = Girder_ent_ob.new
            set_entob(girder_ent_ob)
            object.create_dim

            House.model.commit_operation
            House.entity_group.push(girder_group)
          rescue
            raise "draw_girder_err"
          end 
        when "BFJO::House::Steps"
          begin
            House.model.start_operation('台阶', true)
            steps = object
            layer_name = House.room.get["id"] + object.get["id"]
            layers.add(layer_name)
            House.model.active_layer = layers[layer_name]
            
            p0 = steps.get['points'][0]
            p1 = steps.get['points'][1]
            p2 = steps.get['points'][2]
            p3 = steps.get['points'][3]
            p4 = steps.get['points'][4]
            p5 = steps.get['points'][5]
            p6 = steps.get['points'][6]
            p7 = steps.get['points'][7]
            bottom_face = House.entities.add_face p3,p2,p6,p7
            base_vec = Geom::Vector3d.new(0, 0, 1)
            if bottom_face.normal.angle_between(base_vec) < 0.1
              bottom_face.reverse!
            end
            #上顶面：顺时针绘制
            top_face = House.entities.add_face p4,p5,p1,p0
            if top_face.normal.angle_between(base_vec) > 0.1
              top_face.reverse!
            end

            #侧面：逆时针绘制
            House.entities.add_face p3,p2,p1,p0
            House.entities.add_face p2,p6,p5,p1
            House.entities.add_face p6,p7,p4,p5
            House.entities.add_face p7,p3,p0,p4
           
            steps_group = House.entities.add_group bottom_face.all_connected
            steps_group.set_attribute "house_mobject","type","steps"
            steps_group.set_attribute "house_mobject","id",object.get["id"]
            
            set_entity(steps_group)
            steps_ent_ob = Steps_ent_ob.new
            set_entob(steps_ent_ob)
            House.model.commit_operation
            House.entity_group.push(steps_group)
          rescue
            raise "draw_steps_err"
          end 
        when "BFJO::House::Electricity"
          begin
            dl = House.model.definitions
            electricity_def = ""
            House.model.start_operation('水电', true)
            file_path = Sketchup.find_support_file "#{object.get["type"][1]}.skp","Plugins/bfjo_House/components" #寻找components文件夹下的.skp
            if object.get["type"][0] == 1
              if file_path != nil
                electricity_def = dl.load file_path
              elsif object.get["type"][1] == "cross_cline"
                House.model.active_layer = layers[0]
                point = ""
                electricity_def = dl.add "#{object.get["type"][1]}"
                entities = electricity_def.entities
                point1 = [-45.mm,0,0]
                point2 = [45.mm,0,0]
                point3 = [0,0,-45.mm]
                point4 = [0,0,45.mm]
                entities.add_cline point1,point2
                entities.add_cline point3,point4
                save_path = Sketchup.find_support_file "Plugins/bfjo_House/components",""
                electricity_def.save_as(save_path + "/#{object.get["type"][1]}.skp")
              else
                House.model.active_layer = layers[0]
                point = ""
                electricity_def = dl.add "#{object.get["type"][1]}"
                entities = electricity_def.entities
                point1 = [-45.mm,0,-45.mm]
                point2 = [45.mm,0,-45.mm]
                point3 = [45.mm,-5.mm,-45.mm]
                point4 = [-45.mm,-5.mm,-45.mm]
                face = entities.add_face point1,point2,point3,point4
                face.reverse!
                face.pushpull 90.mm
                path = Sketchup.find_support_file "#{object.get["type"][1]}.png","Plugins/bfjo_House/components"
                point = [-45.mm,-10.mm,-45.mm]
                image = entities.add_image(path,point,90.mm,90.mm)
                vector = Geom::Vector3d.new(1,0,0)
                tr = Geom::Transformation.rotation(point,vector,Math::PI / 2)
                image.transform! tr
                save_path = Sketchup.find_support_file "Plugins/bfjo_House/components",""
                electricity_def.save_as(save_path + "/#{object.get["type"][1]}.skp")
              end
              point = object.get["points"][0]
              layer_name = House.room.get["id"] + "水电"
              layers.add(layer_name)
              House.model.active_layer = layers[layer_name]
              ins = House.entities.add_instance electricity_def,point
              if object.get["type"][1] == "gas_on_ground" || object.get["type"][1] == "drain"
                vector = Geom::Vector3d.new(-1, 0, 0)
              else
                vector = Geom::Vector3d.new(0, 0, 1)
              end
              vector1 = Geom::Vector3d.new(0, -1, 0)
              vector2 = object.get["normal"]
              angle = vector1.angle_between vector2
              rt = Geom::Transformation.rotation(point,vector,angle)
              vector3 = vector1.transform rt
              puts angle
              puts vector3
              puts vector2
              puts vector3.angle_between(vector2)
              if vector3.angle_between(vector2) > 0.01
                angle = 2 * Math::PI - angle
                rt = Geom::Transformation.rotation(point, vector, angle)
              end
              ins.transform! rt
            elsif object.get["type"][0] == 2
              layer_name = House.room.get["id"] + "水电"
              layers.add(layer_name)
              House.model.active_layer = layers[layer_name]
              points = object.get["points"]
              point1 = Geom::Point3d.new(points[1].x,points[1].y,points[1].z)
              point2 = Geom::Point3d.new(points[2].x,points[2].y,points[2].z)
              point3 = Geom::Point3d.new(points[3].x,points[3].y,points[3].z)
              point4 = Geom::Point3d.new(points[4].x,points[4].y,points[4].z)
              h = point1.distance point2
              w = point1.distance point4
              face = House.entities.add_face point1,point2,point3,point4
              vec = face.normal.normalize!
              if vec.angle_between(object.get["normal"]) >= 0.1
                face.reverse!
              end
              vec = face.normal.normalize!
              face.pushpull 5.mm
              vec.length = 16.mm
              tr = Geom::Transformation.translation(vec)
              if object.get["type"][1] == "outlet_on_ceiling"
                vec1 = object.get["edge_vector"]
                vec1.normalize!
                if point3.y < point1.y
                  vec2 = point3 - point2
                  vec2.normalize!
                  if vec1.angle_between(vec2) > 0.01
                    point = point3
                  else
                    point = point2
                  end
                  point.transform! tr
                else
                  vec2 = point1 - point4
                  vec2.normalize!
                  if vec1.angle_between(vec2) > 0.01
                    point = point1
                  else
                    point = point4
                  end
                  point.transform! tr
                end
                rt_vector2 = Geom::Vector3d.new(0,1,0)
              else  
                vec1 = object.get["edge_vector"].normalize
                if point1.z > point3.z
                  vec2 = point3 - point2
                  vec2.normalize!
                  if vec1.angle_between(vec2) > 0.01
                    point = point3
                  else
                    point = point2
                  end
                  point.transform! tr
                else
                  vec2 = point1 - point4
                  vec2.normalize!
                  if vec1.angle_between(vec2) > 0.01
                    point = point1
                  else
                    point = point4
                  end
                  point.transform! tr
                end
                rt_vector2 = Geom::Vector3d.new(0,0,1)
              end
              path = Sketchup.find_support_file "#{object.get["type"][1]}.png","Plugins/bfjo_House/components"
              image = House.entities.add_image(path,point,w,h)
              if object.get["type"][1] != "outlet_on_ceiling"
                rt_vector1 = Geom::Vector3d.new(1,0,0)
                tr1 = Geom::Transformation.rotation(point,rt_vector1,Math::PI / 2)
                image.transform! tr1
              end
              imv = image.normal
              angle = imv.angle_between object.get["normal"]
              tr2 = Geom::Transformation.rotation(point,rt_vector2,angle)
              image.transform! tr2
              if image.normal.angle_between(object.get["normal"]) > 0.01
                tr3 = Geom::Transformation.rotation(point,rt_vector2, -(2 * angle))
                image.transform! tr3
              end
              ins = House.entities.add_group face.all_connected,image
            end
            
            ins.set_attribute "house_mobject","type","electricity"
            ins.set_attribute "house_mobject","id",object.get["id"]

            if object.get["type"][1] == "socket" || object.get["type"][1] == "switch"
              ins_array = []
              l = 90.mm
              inner_face = []
              walls = House.room.get["mobjects"]["BFJO::House::Wall"]
              walls.each{ |wall|
                wpoint = wall.get["inner_points"][0]
                vector = wall.get["normal_vector"]
                plane = [wpoint,vector]
                inner_face.push(plane)
              }
              points = [point]
              mi = Geometry::find_belong_wall(points,inner_face)
              # puts ">>>>>>>>>>>"
              inner_points = walls[mi].get["inner_points"]
              vp1 = Geom::Point3d.new(inner_points[1].x,inner_points[1].y,inner_points[1].z)
              vp2 = Geom::Point3d.new(inner_points[0].x,inner_points[0].y,inner_points[0].z)
              vector = vp1 - vp2
              # puts vector
              for i in 0..object.get["num"] - 2
                # puts "<<<<<<<<wwwwwww"
                new_ins = ins.copy
                vector.length = l
                tr = Geom::Transformation.translation(vector)
                l += 90.mm
                new_ins.transform! tr
                House.entity_group.push(new_ins)
              end
            end
            
            set_entity(ins)
            electricity_ent_ob = Electricity_ent_ob.new
            set_entob(electricity_ent_ob)
            House.model.commit_operation
            House.entity_group.push(ins)
          rescue
            raise "draw_electricity_err"
          end
        when "BFJO::House::Ceilingline"
          # begin
            House.model.start_operation('石膏线', true)
            walls = House.room.get["mobjects"]["BFJO::House::Wall"]
            layer_name = House.room.get["id"] + object.get["id"]
            layers.add(layer_name)
            layer = layers[layer_name]
            House.model.active_layer = layer
            woutter_points = []
            winner_points = []
            trs = []
            inner_face = []
            i = 0
            walls.each{ |wall|  
              #取内墙面2点
              n_wall = walls[(i + 1)%walls.size]
              outter_point_1 = Geom::Point3d.new(wall.get["inner_points"][2].x,wall.get["inner_points"][2].y,wall.get["inner_points"][2].z)
              outter_point_2 = Geom::Point3d.new(wall.get["inner_points"][3].x,wall.get["inner_points"][3].y,wall.get["inner_points"][3].z)

              n_outter_point_1 = Geom::Point3d.new(n_wall.get["inner_points"][2].x,n_wall.get["inner_points"][2].y,n_wall.get["inner_points"][2].z)
              n_outter_point_2 = Geom::Point3d.new(n_wall.get["inner_points"][3].x,n_wall.get["inner_points"][3].y,n_wall.get["inner_points"][3].z)
              vec1 = Geom::Vector3d.new(n_outter_point_2.x - n_outter_point_1.x,n_outter_point_2.y - n_outter_point_1.y,n_outter_point_2.z - n_outter_point_1.z)

              vec1.length = object.get["depth"]
              tr1 = Geom::Transformation.translation(vec1)
              trs.push(tr1)
              woutter_points.push(outter_point_1)
              inner_point_1 = outter_point_1.transform tr1
              inner_point_2 = outter_point_2.transform tr1
              winner_points.push(inner_point_1)
              winner_points.push(inner_point_2)
              plane = [wall.get["inner_points"][0],wall.get["normal_vector"]]
              inner_face.push(plane)
              i += 1
            }

            girders = House.room.get["mobjects"]["BFJO::House::Girder"]
            girder_groups = []
            if girders != nil && girders != []
              girders.each{ |girder|
                if girder.get["type"] == "corner_girder"
                  p1 = Geom::Point3d.new(girder.get["points"][2].x,girder.get["points"][2].y,girder.get["points"][2].z)
                  p2 = Geom::Point3d.new(girder.get["points"][6].x,girder.get["points"][6].y,girder.get["points"][6].z)
                  points = [p1,p2]
                  mi = Geometry::find_belong_wall(points,inner_face)
                  p3 = Geom::Point3d.new(girder.get["points"][3].x,girder.get["points"][3].y,girder.get["points"][3].z)
                  p4 = Geom::Point3d.new(girder.get["points"][7].x,girder.get["points"][7].y,girder.get["points"][7].z)
                  woutter_points[mi] = p3
                  woutter_points[mi + 1] = p4

                  inner_point_1 = p3.transform trs[mi]
                  inner_point_2 = p4.transform trs[mi]
                  inner_point_3 = p4.transform trs[mi + 1]
                  winner_points[2 * mi] = inner_point_1
                  winner_points[2 * mi + 1] = inner_point_2
                  winner_points[2 * mi + 2] = inner_point_3
                # elsif girder.get["type"] == "mid_girder"
                #   p1 = Geom::Point3d.new(girder.get["points"][1].x,girder.get["points"][1].y,girder.get["points"][1].z)
                #   p2 = Geom::Point3d.new(girder.get["points"][2].x,girder.get["points"][2].y,girder.get["points"][2].z)
                #   points = [p1,p2]
                #   mi = Geometry::find_belong_wall(points,inner_face)

                #   # v1 = walls[mi].get["normal_vector"].reverse
                #   # v1.length = object.get["depth"]
                #   # tr1 = Geom::Transformation.translation(v1)
                #   v2 = Geom::Vector3d.new(0,0,-1)
                #   v2.length = object.get["height"][0]
                #   tr2 = Geom::Transformation.translation(v2)
                #   v3 = Geom::Vector3d.new(0,0,-1)
                #   v3.length = object.get["height"][1]
                #   tr3 = Geom::Transformation.translation(v3)

                #   p5 = p1.transform tr3
                #   p6 = p2.transform tr3
                #   p1.transform! tr2
                #   p2.transform! tr2
                #   p3 = p2.transform trs[mi]
                #   p4 = p1.transform trs[mi]
                #   p7 = p6.transform trs[mi]
                #   p8 = p5.transform trs[mi]
                  
                #   face1 = House.entities.add_face p1,p2,p3,p4
                #   House.entities.add_face p5,p6,p7,p8
                #   House.entities.add_face p1,p5,p6,p2
                #   House.entities.add_face p2,p6,p7,p3
                #   House.entities.add_face p3,p7,p8,p4
                #   House.entities.add_face p1,p5,p8,p4
                #   # face1.pushpull object.get["height"]
                #   group1 = House.entities.add_group face1.all_connected

                #   p1 = Geom::Point3d.new(girder.get["points"][5].x,girder.get["points"][5].y,girder.get["points"][5].z)
                #   p2 = Geom::Point3d.new(girder.get["points"][6].x,girder.get["points"][6].y,girder.get["points"][6].z)
                #   points = [p1,p2]
                #   mi = Geometry::find_belong_wall(points,inner_face)
                #   p5 = p1.transform tr3
                #   p6 = p2.transform tr3
                #   p1.transform! tr2
                #   p2.transform! tr2
                #   p3 = p2.transform trs[mi]
                #   p4 = p1.transform trs[mi]
                #   p7 = p6.transform trs[mi]
                #   p8 = p5.transform trs[mi]
                  
                #   face2 = House.entities.add_face p1,p2,p3,p4
                #   House.entities.add_face p5,p6,p7,p8
                #   House.entities.add_face p1,p5,p6,p2
                #   House.entities.add_face p2,p6,p7,p3
                #   House.entities.add_face p3,p7,p8,p4
                #   House.entities.add_face p1,p5,p8,p4
                #   group2 = House.entities.add_group face2.all_connected

                #   girder_groups.push(group1)
                #   girder_groups.push(group2)
                end
              }
            end

            columns = House.room.get["mobjects"]["BFJO::House::Column"]
            column_points = {}
            inner_column_points = {}
            if columns != nil && columns != []
              columns.each{ |column|
                if column.get["type"] == "wall_mid_column"
                  p1 = Geom::Point3d.new(column.get["points"][6].x,column.get["points"][6].y,column.get["points"][6].z)
                  p2 = Geom::Point3d.new(column.get["points"][7].x,column.get["points"][7].y,column.get["points"][7].z)
                  points = [p1,p2]
                  mi = Geometry::find_belong_wall(points,inner_face)

                  if column_points["#{mi}"] == nil
                    column_points["#{mi}"] = []
                  end
                  p3 = Geom::Point3d.new(column.get["points"][5].x,column.get["points"][5].y,column.get["points"][5].z)
                  p4 = Geom::Point3d.new(column.get["points"][4].x,column.get["points"][4].y,column.get["points"][4].z)
                  v1 = column.get["points"][7] - column.get["points"][6]
                  inner_points = walls[mi].get["inner_points"]
                  vp1 = Geom::Point3d.new(inner_points[3].x,inner_points[3].y,inner_points[3].z)
                  vp2 = Geom::Point3d.new(inner_points[2].x,inner_points[2].y,inner_points[2].z)
                  v2 = vp1 - vp2
                  if v2.angle_between(v1) > 0.01
                    temp = p1
                    p1 = p2
                    p2 = temp
                    temp = p3
                    p3 = p4
                    p4 = temp
                  end
                  column_points["#{mi}"].push(p1)
                  column_points["#{mi}"].push(p3)
                  column_points["#{mi}"].push(p4)
                  column_points["#{mi}"].push(p2)

                  if inner_column_points["#{mi}"] == nil
                    inner_column_points["#{mi}"] = []
                  end
                  v1 = v2.reverse
                  v1.length = object.get["depth"]
                  tr1 = Geom::Transformation.translation(v1)
                  inner_p1 = p1.transform tr1
                  inner_p2 = p3.transform tr1
                  v2 = column.get["points"][5] - column.get["points"][6]
                  v2 = Geom::Vector3d.new(v2.x,v2.y,v2.z)
                  v2.length = object.get["depth"]
                  tr2 = Geom::Transformation.translation(v2)
                  inner_p3 = p3.transform tr2
                  inner_p4 = p4.transform tr2
                  inner_p7 = p2.transform tr2
                  inner_p8 = winner_points[2 * mi + 1]
                  v3 = v1.reverse
                  v3.length = object.get["depth"]
                  tr3 = Geom::Transformation.translation(v3)
                  inner_p5 = p4.transform tr3
                  inner_p6 = p2.transform tr3

                  inner_column_points["#{mi}"].push(inner_p1)
                  inner_column_points["#{mi}"].push(inner_p2)
                  inner_column_points["#{mi}"].push(inner_p3)
                  inner_column_points["#{mi}"].push(inner_p4)
                  inner_column_points["#{mi}"].push(inner_p5)
                  inner_column_points["#{mi}"].push(inner_p6)
                  inner_column_points["#{mi}"].push(inner_p7)
                  inner_column_points["#{mi}"].push(inner_p8)
                elsif column.get["type"] == "corner_column"
                  p1 = Geom::Point3d.new(column.get["points"][1].x,column.get["points"][1].y,column.get["points"][1].z)
                  p2 = Geom::Point3d.new(column.get["points"][2].x,column.get["points"][2].y,column.get["points"][2].z)
                  points = [p1,p2]
                  mi = Geometry::find_belong_wall(points,inner_face)

                  if column_points["#{mi}"] == nil
                    column_points["#{mi}"] = []
                  end
                  if column_points["#{mi + 1}"] == nil
                    column_points["#{mi + 1}"] = []
                  end

                  p3 = Geom::Point3d.new(column.get["points"][5].x,column.get["points"][5].y,column.get["points"][5].z)
                  p4 = Geom::Point3d.new(column.get["points"][4].x,column.get["points"][4].y,column.get["points"][4].z)

                  column_points["#{mi}"].push(p3)
                  column_points["#{mi}"].push(p4)
                  woutter_points[mi + 1] = Geom::Point3d.new(column.get["points"][7].x,column.get["points"][7].y,column.get["points"][7].z)

                  v1 = column.get["points"][4] - column.get["points"][7]
                  v1 = Geom::Vector3d.new(v1.x,v1.y,v1.z)
                  v1.length = object.get["depth"]
                  tr1 = Geom::Transformation.translation(v1)
                  inner_p1 = column.get["points"][5].transform tr1
                  inner_p2 = column.get["points"][4].transform tr1
                  v2 = column.get["points"][4] - column.get["points"][5]
                  v2 = Geom::Vector3d.new(v2.x,v2.y,v2.z)
                  v2.length = object.get["depth"]
                  tr2 = Geom::Transformation.translation(v2)
                  inner_p3 = column.get["points"][4].transform tr2
                  inner_p4 = column.get["points"][7].transform tr2

                  if inner_column_points["#{mi}"] == nil
                    inner_column_points["#{mi}"] = []
                  end
                  inner_column_points["#{mi}"].push(inner_p1)
                  inner_column_points["#{mi}"].push(inner_p2)
                  inner_column_points["#{mi}"].push(inner_p3)
                  inner_column_points["#{mi}"].push(inner_p4)
                end
              }
            end

            # door_groups = []
            # doors = House.room.get["mobjects"]["BFJO::House::Door"]
            # if doors != nil && doors != []
            #   doors.each{ |door|  
            #     door_point_1 = [door.get["points"][0].x,door.get["points"][0].y,door.get["points"][0].z]
            #     door_point_2 = [door.get["points"][1].x,door.get["points"][1].y,door.get["points"][1].z]
            #     if door_point_1.z < door_point_2.z
            #       door_height = door_point_1.z
            #       door_point_2.z = door_point_1.z
            #     else
            #       door_height = door_point_2.z
            #       door_point_1.z = door_point_2.z
            #     end
            #     s = door.get["wid"].to_i - 1
            #     door_point_3 = door_point_2.transform trs[s]
            #     door_point_4 = door_point_1.transform trs[s]
            #     door_face = House.entities.add_face door_point_1,door_point_2,door_point_3,door_point_4
            #     door_face.reverse!
            #     door_face.pushpull object.get["height"] - door_height
            #     door_group = House.entities.add_group door_face.all_connected
            #     door_groups.push(door_group)
            #   }
            # end

            outter_points = []
            inner_points = []
            for i in 0..(walls.size - 1)
              outter_points.push(woutter_points[i])
              puts column_points["#{i}"]
              if column_points["#{i}"] != nil

                column_points["#{i}"].each{ |cp|  
                  outter_points.push(cp)
                }
              end
              puts inner_column_points["#{i}"]
              inner_points.push(winner_points[2 * i])
              inner_points.push(winner_points[2 * i + 1])
              if inner_column_points["#{i}"] != nil
                inner_column_points["#{i}"].each{ |cp|  
                  inner_points.push(cp)
                }
              end
            end

            calculated_inner_points = []
            for i in 0..(inner_points.size - 1)
              if i % 2 != 0
                point1 = inner_points[i]
                point2 = inner_points[i - 1]
                if i == 1
                  point3 = inner_points[inner_points.size - 2]
                  point4 = inner_points[inner_points.size - 1]
                else
                  point3 = inner_points[i - 3]
                  point4 = inner_points[i - 2]
                end
                calculated_inner_point = Geometry::intersect_between_lines(point1,point2,point3,point4)
                # puts ""
                calculated_inner_points.push(calculated_inner_point)
              end
              i += 1
            end

            ceiline_height = object.get["height"][1]
            zaxis_vector = Geom::Vector3d.new(0,0,-1)
            zaxis_vector.length = ceiline_height
            ceilingline_top_tr = Geom::Transformation.translation(zaxis_vector)

            outter_points.each{ |p|  
              p.transform! ceilingline_top_tr
            }
            calculated_inner_points.each{ |p|  
              p.transform! ceilingline_top_tr
            }

            #所要添加的石膏线的面的数量:点的数量对应面的数量（点的数量>2)
            outter_points_size = outter_points.size

            face_count = outter_points_size
            #石膏线的高度
            ceiline_height = object.get["height"][0] - object.get["height"][1]
            zaxis_vector = Geom::Vector3d.new(0,0,-1)
            zaxis_vector.length = ceiline_height
            ceilingline_tr = Geom::Transformation.translation(zaxis_vector)

            outter_bottom_points = []
            inner_bottom_points = []

            for i in 0..(outter_points_size-1)
              outter_bottom_points[i] = outter_points[i].transform ceilingline_tr
              inner_bottom_points[i] = calculated_inner_points[i].transform ceilingline_tr
            end
            #画围成石膏线的侧面 
            for i in 0..(face_count-1)
              #下一个点的坐标
              next_point_index = (i+1) % outter_points_size

              inner_top_point_current = calculated_inner_points[i]
              inner_bottom_point_current = inner_bottom_points[i]
              
              inner_top_point_next = calculated_inner_points[next_point_index]
              inner_bottom_point_next = inner_bottom_points[next_point_index]

              outter_top_point_current = outter_points[i]
              outter_bottom_point_current = outter_bottom_points[i]

              outter_top_point_next = outter_points[next_point_index]
              outter_bottom_point_next = outter_bottom_points[next_point_index]

              inner_face_points = [inner_top_point_current,inner_top_point_next,inner_bottom_point_next,inner_bottom_point_current]
              House.entities.add_face inner_face_points

              outter_face_points = [outter_top_point_current,outter_top_point_next,outter_bottom_point_next,outter_bottom_point_current]
              House.entities.add_face outter_face_points
            end

            outter_top_face = House.entities.add_face outter_points
            outter_bottom_face = House.entities.add_face outter_bottom_points
            group1 = House.entities.add_group outter_top_face.all_connected

            inner_top_face = House.entities.add_face calculated_inner_points
            inner_bottom_face = House.entities.add_face inner_bottom_points
            group2 = House.entities.add_group inner_top_face.all_connected

            ceilingline_group = group2.subtract(group1)
            if girder_groups != []
              girder_groups.each{ |girder_group|  
                ceilingline_group = girder_group.subtract(ceilingline_group)
              }
            end
            ceilingline_group.set_attribute "house_mobject","type","ceilingline"
            ceilingline_group.set_attribute "house_mobject","id",object.get["id"]
            
            set_entity(ceilingline_group)
            ceilingline_ent_ob = Ceilingline_ent_ob.new
            set_entob(ceilingline_ent_ob)
            House.model.commit_operation
            House.entity_group.push(ceilingline_group)
          # rescue 
            # raise "draw_ceilingline_err"
          # end
        when "BFJO::House::Suspended_ceiling"
          # begin
            House.model.start_operation('吊顶', true)
            walls = House.room.get["mobjects"]["BFJO::House::Suspended_ceiling"]
            layer_name = House.room.get["id"] + "吊顶"
            layers.add(layer_name)
            layer = layers[layer_name]
            House.model.active_layer = layer
            cline = House.entities.add_cline object.get["points"][0],object.get["points"][1]
            House.model.commit_operation
            House.entity_group.push(cline)
          # rescue
          #   raise "draw_suspended_ceiling_err"
          # end
        end
      end
    end

    class CHouse
      def initialize
        @rooms = {}
        @house_name
        @used_to_return = {"rooms"=>@rooms,"house_name"=>@house_name}
      end

      def set_room(room,room_id)
        @rooms["#{room_id}"] = room
      end

      def set_name(house_name)
        @house_name = house_name
        @used_to_return["house_name"] = house_name
      end

      def draw(house_hash)
        # if @house_name == nil
          # @house_name = house_hash["house_name"]
          # @used_to_return["house_name"] = @house_name
          # i = 0
          # @house_name.each{ |h|
          #   if h != ""
          #     point = [0,i,0]
          #     House.entities.add_text h,point
          #     i += 30.mm
          #   end
          # }
        # end
        rooms = house_hash["rooms"]
        croom = ""
        if rooms != nil
          rooms.each{ |room_hash|
            room_name = room_hash["room_name"]
            House.house.get["rooms"].each{ |r,v| 
              if /#{room_name}/.match("#{v.get["id"]}")
                room_name = room_name + "*"
              end
            }
            room_hash["room_name"] = room_name
            House.entity_group = []
            croom = Room.new
            House.room = croom
            croom.draw(room_hash)
            @rooms["#{croom.get["id"]}"] = croom
          }
        end
      end

      def get
        return @used_to_return
      end
    end

    class MDimension
      def initialize
        @dims = []
        @used_to_return = {"dims" => @dims}
      end

      def clear_dim
        @dims.each{ |dim|
          dim.visible = true
          Sketchup.active_model.active_entities.erase_entities dim
        }
        @dims = []
      end

      def set_dim(dim)
        @dims.push(dim)
      end

      def show_dim
        @dims.each{ |dim|  
          dim.visible = true
        }
      end

      def hide_dim
        @dims.each{ |dim|  
          dim.visible = false
        }
      end

      def create_dim(start,endp,offset,object,methodname,tiptype)
        a_entities = Sketchup.active_model.active_entities
        dim = a_entities.add_dimension_linear(start,endp,offset)
        dim.set_attribute "house_dim","belong_object",object
        dim.set_attribute "house_dim","methodname",methodname
        dim.set_attribute "house_dim","tiptype",tiptype
        mydimob = MyDimensionObserver.new
        dim.add_observer mydimob
        House.entity_group.push(dim)
        dim.visible = false
        set_dim(dim)
      end

      def redraw_height(dimension,direct,object)
        a_entities = Sketchup.active_model.active_entities
        layers = House.model.layers
        materials = House.model.materials
        fill_vacancy(object)
        case object.class.to_s
        when "BFJO::House::Door"  
          point1 = object.get["points"][0]
          point2 = object.get["points"][1]
          if point1.z < point2.z
            temp = point1
            point1 = point2
            point2 = temp
          end
          if direct == "上"
            point1.z = point2.z + dimension.to_f.mm
          else
            point2.z = point1.z - dimension.to_f.mm
          end
        when "BFJO::House::Window"
          if object.get["type"] == "normal_window" || object.get["type"] == "bay_window"
            if object.get["type"] == "bay_window"
              a_entities.erase_entities object.get["su_model"].get["entity"]
            end

            point1 = object.get["points"][0]
            point2 = object.get["points"][1]
            if point1.z < point2.z
              temp = point1
              point1 = point2
              point2 = temp
            end
            if direct == "上"
              point1.z = point2.z + dimension.to_f.mm
            else
              point2.z = point1.z - dimension.to_f.mm
            end
          elsif object.get["type"] == "L_bay_window"
            a_entities.erase_entities object.get["su_model"].get["entity"]

            point1 = object.get["points"][0]
            point2 = object.get["points"][1]
            point3 = object.get["points"][2]
            point4 = object.get["points"][3]
            if direct == "上"
              point1.z = point2.z + dimension.to_f.mm
            else
              point2.z = point1.z - dimension.to_f.mm
              point3.z = point1.z - dimension.to_f.mm
              point4.z = point1.z - dimension.to_f.mm
            end
            
          end
        end
        object.get["mdimension"].clear_dim
        object.get["su_model"].draw(object)
      end

      def redraw_width(dimension,direct,object)
        a_entities = Sketchup.active_model.active_entities
        layers = House.model.layers
        materials = House.model.materials
        walls = House.room.get["mobjects"]["BFJO::House::Wall"]
        case object.class.to_s
        when "BFJO::House::Wall"
          if House.is_measure_end == 1 || House.last_measure != ""
            Sketchup.undo
            UI.messagebox("无法修改墙的尺寸")
            return
          end

          m = object.get["id"].reverse.to_i - 1
          if m == 0
            wall = walls[walls.size - 1]
          else
            wall = walls[m - 1]
          end
          wall = walls[(m + 1) % walls.size]
          inner_points1 = object.get["inner_points"]
          inner_point1 = inner_points1[0]
          inner_point2 = inner_points1[1]
          inner_point3 = wall.get["inner_points"][1]
          d = inner_point2.distance inner_point3

          line2_length = d
          new_length = dimension.to_f.mm
          temp_point = inner_point2
          x1 = inner_point1.x
          y1 = inner_point1.y
          x2 = inner_point3.x
          y2 = inner_point3.y
          l3 = ((x1 - x2) ** 2 + (y1 - y2) ** 2) ** (1 / 2.0) 
          l3 = l3
          if (l3 + line2_length < new_length) || (l3 + new_length < line2_length) || (line2_length + new_length < l3)
            UI.messagebox("输入数据错误")
            Sketchup.undo
            return
          else
            q = new_length ** 2 - line2_length ** 2 + x2 ** 2 - x1 ** 2 + y2 ** 2 - y1 ** 2
            e = x2 - x1
            f = y2 - y1
            a = (f ** 2 + e ** 2)  # a * y ** 2 + b * y + c = 0
            b = 2 * x1 * f * e - q * f - 2 * y1 * (e ** 2)
            c = (q ** 2) / 4.0 - x1 * q * e + (x1 ** 2 + y1 ** 2 - new_length ** 2) * ((x2 - x1) ** 2)
            new_y1 = ((b ** 2) / (4 * a ** 2) - c / a) ** (1 / 2.0) - b / (2 * a)
            new_x1 = q / (2 * e) - new_y1 * f / e
            new_y2 = -((b ** 2) / (4 * a ** 2) - c / a) ** (1 / 2.0) - b / (2 * a)
            new_x2 = q / (2 * e) - new_y2 * f / e
            tempp_x = temp_point.x.to_f
            tempp_y = temp_point.y.to_f
            l1 = ((new_x1 - tempp_x) ** 2 + (new_y1 - tempp_y) ** 2) ** (1 / 2.0)
            l2 = ((new_x2 - tempp_x) ** 2 + (new_y2 - tempp_y) ** 2) ** (1 / 2.0)
            if l1 < l2
              new_x = new_x1
              new_y = new_y1
            else 
              new_x = new_x2
              new_y = new_y2
            end
            new_point = [new_x,new_y,0]
          end

          inner_point2 = Geom::Point3d.new(new_point.x,new_point.y,new_point.z)
          v2 = object.get["normal_vector"]
          v2.length = object.get["thickness"]
          tr2 = Geom::Transformation.new(v2)
          outter_point1 = inner_point2.transform v2
          outter_point2 = object.get["outter_points"][0]
          v3 = wall.get["normal_vector"]
          v3.length = wall.get["thickness"]
          tr3 = Geom::Transformation.new(v3)
          outter_point3 = inner_point2.transform v3
          outter_point4 = wall.get["outter_points"][1]
          intersect_point = Geometry::intersect_between_lines(outter_point1,outter_point2,outter_point3,outter_point4)

          object.set_inner_point(1,inner_point2)
          wall.set_inner_point(0,inner_point2)
          object.set_outter_point(1,intersect_point)
          wall.set_outter_point(0,intersect_point)

          outter_point5 = wall.get["outter_points"][2]
          outter_point5.x = intersect_point.x
          outter_point5.y = intersect_point.y
          outter_point6 = object.get["outter_points"][3]
          outter_point6.x = intersect_point.x
          outter_point6.y = intersect_point.y

          inner_point3 = inner_points1[3]
          inner_point3.x = inner_point2.x
          inner_point3.y = inner_point2.y
          inner_point4 = wall.get["inner_points"][2]
          inner_point4.x = inner_point2.x
          inner_point4.y = inner_point2.y

          vector1 = House.room.get["floor_vector"] #获取地面法向量
          vector2 = inner_point1.vector_to(inner_point2)
          wall_vector = vector1 * vector2
          wall_vector.length = House.wall_thickness
          object.set_normal_vector(wall_vector)

          vector3 = inner_point2.vector_to(wall.get["inner_points"][1])
          wall_vector = vector1 * vector3
          wall_vector.length = House.wall_thickness
          wall.set_normal_vector(wall_vector)

          House.entities.erase_entities object.get["su_model"].get["entity"]
          House.entities.erase_entities object.get["su_model"].get["text"]
          House.entities.erase_entities wall.get["su_model"].get["entity"]
          House.entities.erase_entities wall.get["su_model"].get["text"]
          wall.get["mdimension"].clear_dim
          wall.get["su_model"].draw(wall)
        when "BFJO::House::Door"
          fill_vacancy(object)
          m = object.get["wid"].to_i - 1
          wall = walls[m]
          point1 = object.get["points"][0]
          point2 = object.get["points"][1]
          inner_points = wall.get["inner_points"]
          check_point1 = Geom::Point3d.new(inner_points[0].x,inner_points[0].y,point1.z)
          check_point2 = Geom::Point3d.new(inner_points[0].x,inner_points[0].y,point2.z)
          d1 = point1.distance check_point1
          d2 = point2.distance check_point2
          if d1 > d2
            temp = point1
            point1 = point2
            point2 = temp
          end

          p2 = Geom::Point3d.new(point2.x,point2.y,point1.z)
          d = point1.distance p2
          check_point1.z = point1.z
          check_point2 = Geom::Point3d.new(inner_points[1].x,inner_points[1].y,point1.z)
          if direct == "左"
            if d > dimension.to_f.mm
              v =  check_point2 - check_point1
              v.length = d - dimension.to_f.mm
            else
              v = check_point1 - check_point2
              v.length = dimension.to_f.mm - d
            end
            tr = Geom::Transformation.new(v)
            point1.transform! tr
          else
            if d > dimension.to_f.mm
              v = check_point1 - check_point2
              v.length = d - dimension.to_f.mm
            else
              v = check_point2 - check_point1
              v.length = dimension.to_f.mm - d
            end
            tr = Geom::Transformation.new(v)
            point2.transform! tr
          end
        when "BFJO::House::Window"
          fill_vacancy(object)
          if object.get["type"] == "normal_window" || object.get["type"] == "bay_window"
            if object.get["type"] == "bay_window"
              a_entities.erase_entities object.get["su_model"].get["entity"]
            end

            m = object.get["wid"].to_i - 1
            wall = walls[m]
            point1 = object.get["points"][0]
            point2 = object.get["points"][1]
            inner_points = wall.get["inner_points"]
            check_point1 = Geom::Point3d.new(inner_points[0].x,inner_points[0].y,point1.z)
            check_point2 = Geom::Point3d.new(inner_points[0].x,inner_points[0].y,point2.z)
            d1 = point1.distance check_point1
            d2 = point2.distance check_point2
            if d1 > d2
              temp = point1
              point1 = point2
              point2 = temp
            end

            p2 = Geom::Point3d.new(point2.x,point2.y,point1.z)
            d = point1.distance p2
            check_point1.z = point1.z
            check_point2 = Geom::Point3d.new(inner_points[1].x,inner_points[1].y,point1.z)
            if direct == "左"
              if d > dimension.to_f.mm
                v =  check_point2 - check_point1
                v.length = d - dimension.to_f.mm
              else
                v = check_point1 - check_point2
                v.length = dimension.to_f.mm - d
              end
              tr = Geom::Transformation.new(v)
              point1.transform! tr
            else
              if d > dimension.to_f.mm
                v = check_point1 - check_point2
                v.length = d - dimension.to_f.mm
              else
                v = check_point2 - check_point1
                v.length = dimension.to_f.mm - d
              end
              tr = Geom::Transformation.new(v)
              point2.transform! tr
            end
          elsif object.get["type"] == "L_bay_window"
            a_entities.erase_entities object.get["su_model"].get["entity"]
            id = object.get["wid"].split(",")
            wall1 = walls[id[0].to_i - 1]
            wall2 = walls[id[1].to_i - 1]
            if direct == "左"
              point1 = object.get["points"][0]
              point2 = object.get["points"][2]
              inner_points = wall1.get["inner_points"]
              check_point1 = Geom::Point3d.new(inner_points[0].x,inner_points[0].y,point2.z)
              check_point2 = Geom::Point3d.new(inner_points[1].x,inner_points[1].y,point2.z)
              plane = [inner_points[0],wall1.get["normal_vector"]]
              point3 = point2.project_to_plane plane
              d = check_point2.distance point3
              # puts d.mm
              if d > dimension.to_f.mm
                v = check_point2 - check_point1
                v.length = d - dimension.to_f.mm
              else
                v = check_point1 - check_point2
                v.length = dimension.to_f.mm - d
              end
              tr = Geom::Transformation.new(v)
              point1.transform! tr
              point2.transform! tr
            elsif direct == "右"
              inner_points = wall2.get["inner_points"]
              point1 = object.get["points"][1]
              check_point1 = Geom::Point3d.new(inner_points[0].x,inner_points[0].y,point1.z)
              check_point2 = Geom::Point3d.new(inner_points[1].x,inner_points[1].y,point1.z)
              plane = [inner_points[0],wall2.get["normal_vector"]]
              point2 = point1.project_to_plane plane
              d = check_point1.distance point2
              if d > dimension.to_f.mm
                v = check_point1 - check_point2
                v.length = d - dimension.to_f.mm
              else
                v = check_point2 - check_point1
                v.length = dimension.to_f.mm - d
              end
              tr = Geom::Transformation.new(v)
              point1.transform! tr
            end
          end
        end
        object.get["mdimension"].clear_dim
        object.get["su_model"].draw(object)
      end

      def redraw_right2wall(dimension,direct,object)
        a_entities = Sketchup.active_model.active_entities
        layers = House.model.layers
        materials = House.model.materials
        walls = House.room.get["mobjects"]["BFJO::House::Wall"]
        fill_vacancy(object)
        case object.class.to_s
        when "BFJO::House::Door"
          m = object.get["wid"].to_i - 1
          wall = walls[m]
          point1 = object.get["points"][0]
          point2 = object.get["points"][1]
          inner_points = wall.get["inner_points"]
          check_point1 = Geom::Point3d.new(inner_points[0].x,inner_points[0].y,point1.z)
          check_point2 = Geom::Point3d.new(inner_points[0].x,inner_points[0].y,point2.z)
          d1 = point1.distance check_point1
          d2 = point2.distance check_point2
          if d1 > d2
            temp = point1
            point1 = point2
            point2 = temp
          end

          p2 = Geom::Point3d.new(point2.x,point2.y,point1.z)
          check_point2 = Geom::Point3d.new(inner_points[1].x,inner_points[1].y,point1.z)
          d = check_point2.distance p2
          
          if d > dimension.to_f.mm
            v = check_point2 - check_point1
            v.length = d - dimension.to_f.mm
          else
            v = check_point1 - check_point2
            v.length = dimension.to_f.mm - d
          end
          tr = Geom::Transformation.new(v)
          point2.transform! tr
        when "BFJO::House::Window"
          if object.get["type"] == "normal_window" || object.get["type"] == "bay_window"

            if object.get["type"] == "bay_window"
              a_entities.erase_entities object.get["su_model"].get["entity"]
            end

            walls = House.room.get["mobjects"]["BFJO::House::Wall"]
            m = object.get["wid"].to_i - 1
            wall = walls[m]
            point1 = object.get["points"][0]
            puts point1
            point2 = object.get["points"][1]
            inner_points = wall.get["inner_points"]
            check_point1 = Geom::Point3d.new(inner_points[0].x,inner_points[0].y,point1.z)
            puts ">>>>>>>"
            a_entities.add_cpoint point1
            a_entities.add_cpoint check_point1
            puts point1,check_point1
            check_point2 = Geom::Point3d.new(inner_points[0].x,inner_points[0].y,point2.z)
            d1 = point1.distance check_point1
            d2 = point2.distance check_point2
            if d1 > d2
              temp = point1
              point1 = point2
              point2 = temp
            end

            p2 = Geom::Point3d.new(point2.x,point2.y,point1.z)
            check_point2 = Geom::Point3d.new(inner_points[1].x,inner_points[1].y,point1.z)
            d = check_point2.distance p2
            
            if d > dimension.to_f.mm
              v = check_point2 - check_point1
              v.length = d - dimension.to_f.mm
            else
              v = check_point1 - check_point2
              v.length = dimension.to_f.mm - d
            end
            tr = Geom::Transformation.new(v)
            point2.transform! tr
          elsif object.get["type"] == "L_bay_window"
            a_entities.erase_entities object.get["su_model"].get["entity"]

            id = object.get["wid"].split(",")
            wall1 = walls[id[0].to_i - 1]
            wall2 = walls[id[1].to_i - 1]
            inner_points = wall2.get["inner_points"]
            point1 = object.get["points"][1]
            check_point1 = Geom::Point3d.new(inner_points[0].x,inner_points[0].y,point1.z)
            check_point2 = Geom::Point3d.new(inner_points[1].x,inner_points[1].y,point1.z)
            plane = [inner_points[0],wall2.get["normal_vector"]]
            point2 = point1.project_to_plane plane
            d = check_point2.distance point2
            if d > dimension.to_f.mm
              v = check_point2 - check_point1
              v.length = d - dimension.to_f.mm
            else
              v = check_point1 - check_point2
              v.length = dimension.to_f.mm - d
            end
            tr = Geom::Transformation.new(v)
            point1.transform! tr
          end
        end
        object.get["mdimension"].clear_dim
        object.get["su_model"].draw(object)
      end

      def redraw_left2wall(dimension,direct,object)
        a_entities = Sketchup.active_model.active_entities
        layers = House.model.layers
        materials = House.model.materials
        walls = House.room.get["mobjects"]["BFJO::House::Wall"]
        fill_vacancy(object)
        case object.class.to_s
        when "BFJO::House::Door"
          m = object.get["wid"].to_i - 1
          wall = walls[m]
          point1 = object.get["points"][0]
          point2 = object.get["points"][1]
          inner_points = wall.get["inner_points"]
          check_point1 = Geom::Point3d.new(inner_points[0].x,inner_points[0].y,point1.z)
          check_point2 = Geom::Point3d.new(inner_points[0].x,inner_points[0].y,point2.z)
          d1 = point1.distance check_point1
          d2 = point2.distance check_point2
          if d1 > d2
            temp = point1
            point1 = point2
            point2 = temp
          end

          check_point2 = Geom::Point3d.new(inner_points[1].x,inner_points[1].y,point1.z)
          d = check_point1.distance point1
          
          if d > dimension.to_f.mm
            v = check_point1 - check_point2
            v.length = d - dimension.to_f.mm
          else
            v = check_point2 - check_point1
            v.length = dimension.to_f.mm - d
          end
          tr = Geom::Transformation.new(v)
          point1.transform! tr
        when "BFJO::House::Window"
          if object.get["type"] == "normal_window" || object.get["type"] == "bay_window"

            if object.get["type"] == "bay_window"
              a_entities.erase_entities object.get["su_model"].get["entity"]
            end

            walls = House.room.get["mobjects"]["BFJO::House::Wall"]
            m = object.get["wid"].to_i - 1
            wall = walls[m]
            point1 = object.get["points"][0]
            point2 = object.get["points"][1]
            inner_points = wall.get["inner_points"]
            check_point1 = Geom::Point3d.new(inner_points[0].x,inner_points[0].y,point1.z)
            check_point2 = Geom::Point3d.new(inner_points[0].x,inner_points[0].y,point2.z)
            d1 = point1.distance check_point1
            d2 = point2.distance check_point2
            if d1 > d2
              temp = point1
              point1 = point2
              point2 = temp
            end

            check_point2 = Geom::Point3d.new(inner_points[1].x,inner_points[1].y,point1.z)
            d = check_point1.distance point1
            
            if d > dimension.to_f.mm
              v = check_point1 - check_point2
              v.length = d - dimension.to_f.mm
            else
              v = check_point2 - check_point1
              v.length = dimension.to_f.mm - d
            end
            tr = Geom::Transformation.new(v)
            point1.transform! tr
          elsif object.get["type"] == "L_bay_window"
            a_entities.erase_entities object.get["su_model"].get["entity"]

            id = object.get["wid"].split(",")
            wall1 = walls[id[0].to_i - 1]
            wall2 = walls[id[1].to_i - 1]

            point1 = object.get["points"][0]
            point2 = object.get["points"][2]
            inner_points = wall1.get["inner_points"]
            check_point1 = Geom::Point3d.new(inner_points[0].x,inner_points[0].y,point2.z)
            check_point2 = Geom::Point3d.new(inner_points[1].x,inner_points[1].y,point2.z)
            plane = [inner_points[0],wall1.get["normal_vector"]]
            point3 = point2.project_to_plane plane
            d = check_point1.distance point3
            # puts d.mm
            if d > dimension.to_f.mm
              v = check_point1 - check_point2
              v.length = d - dimension.to_f.mm
            else
              v = check_point2 - check_point1
              v.length = dimension.to_f.mm - d
            end
            tr = Geom::Transformation.new(v)
            point1.transform! tr
            point2.transform! tr
          end
        end
        object.get["mdimension"].clear_dim
        object.get["su_model"].draw(object)
      end

      def redraw_depth(dimension,direct,object)
        a_entities = Sketchup.active_model.active_entities
        layers = House.model.layers
        materials = House.model.materials
        fill_vacancy(object)
        walls = House.room.get["mobjects"]["BFJO::House::Wall"]
        case object.class.to_s
        when "BFJO::House::Window"
          a_entities.erase_entities object.get["su_model"].get["entity"]
          if object.get["type"] == "bay_window"
            point1 = object.get["points"][2]
            m = object.get["wid"].to_i - 1
            wall = walls[m]
            inner_points = wall.get["inner_points"]
            plane = [inner_points[0],wall.get["normal_vector"]]
            d = point1.distance_to_plane plane
            if d > dimension.to_f.mm
              v = wall.get["normal_vector"].reverse
              v.length = d - dimension.to_f.mm
            elsif d < dimension.to_f.mm
              v = wall.get["normal_vector"]
              v.length = dimension.to_f.mm - d
            end
            tr = Geom::Transformation.new(v)
            point1.transform! tr
          elsif object.get["type"] == "L_bay_window"
            id = object.get["wid"].split(",")
            wall1 = walls[id[0].to_i - 1]
            wall2 = walls[id[1].to_i - 1]
            if direct == "左"
              point1 = object.get["points"][0]
              point2 = object.get["points"][2]
              point3 = object.get["points"][3]
              inner_points = wall1.get["inner_points"]
              plane = [inner_points[0],wall1.get["normal_vector"]]
              d = point1.distance_to_plane plane
              puts d
              if d > dimension.to_f.mm
                v = wall1.get["normal_vector"].reverse
                v.length = d - dimension.to_f.mm
              elsif d < dimension.to_f.mm
                v = wall1.get["normal_vector"]
                v.length = dimension.to_f.mm - d
              end
              tr = Geom::Transformation.new(v)
              point1.transform! tr
              point2.transform! tr
              point3.transform! tr
            elsif direct == "右"
              point1 = object.get["points"][1]
              point2 = object.get["points"][3]
              inner_points = wall2.get["inner_points"]
              plane = [inner_points[0],wall2.get["normal_vector"]]
              d = point1.distance_to_plane plane
              if d > dimension.to_f.mm
                v = wall2.get["normal_vector"].reverse
                v.length = d - dimension.to_f.mm
              elsif d < dimension.to_f.mm
                v = wall2.get["normal_vector"]
                v.length = dimension.to_f.mm - d
              end
              tr = Geom::Transformation.new(v)
              point1.transform! tr
              point2.transform! tr
            end
          end
        end
        object.get["mdimension"].clear_dim
        object.get["su_model"].draw(object)
      end

      def redraw_ground(dimension,direct,object)
        a_entities = Sketchup.active_model.active_entities
        layers = House.model.layers
        materials = House.model.materials
        fill_vacancy(object)
        case object.class.to_s
        when "BFJO::House::Door"
          point1 = object.get["points"][0]
          point2 = object.get["points"][1]
          if point1.z < point2.z
            temp = point1
            point1 = point2
            point2 = temp
          end
          point2.z = dimension.to_f.mm
        when "BFJO::House::Window"
          if object.get["type"] == "normal_window" || object.get["type"] == "bay_window"
            if object.get["type"] == "bay_window"
              a_entities.erase_entities object.get["su_model"].get["entity"]
            end
            point1 = object.get["points"][0]
            point2 = object.get["points"][1]
            if point1.z < point2.z
              temp = point1
              point1 = point2
              point2 = temp
            end
            point2.z = dimension.to_f.mm
          elsif object.get["type"] == "L_bay_window"
            a_entities.erase_entities object.get["su_model"].get["entity"]
            point1 = object.get["points"][1]
            point2 = object.get["points"][2]
            point3 = object.get["points"][3]
            point1.z = dimension.to_f.mm
            point2.z = dimension.to_f.mm
            point3.z = dimension.to_f.mm
          end
        end
        object.get["mdimension"].clear_dim
        object.get["su_model"].draw(object)
      end

      def fill_vacancy(object)
        a_entities = Sketchup.active_model.active_entities
        layers = House.model.layers
        materials = House.model.materials
        #填上空缺
        walls = House.room.get["mobjects"]["BFJO::House::Wall"]
        if object.get["type"] == "L_bay_window"
          id = object.get["wid"].split(",")
          wall1 = walls[id[0].to_i - 1]
          wall2 = walls[id[1].to_i - 1]
          wall_thickness_1 = wall1.get["thickness"]
          wall_thickness_2 = wall2.get["thickness"]
          wall_thickness = [wall_thickness_1,wall_thickness_2]
          plane_1 = [wall1.get["inner_points"][0],wall1.get["normal_vector"]]
          plane_2 = [wall2.get["inner_points"][0],wall2.get["normal_vector"]]
          dis1 = object.get["points"][0].distance_to_plane plane_1
          dis2 = object.get["points"][1].distance_to_plane plane_2
          base_vec = Geom::Vector3d.new(0, 0, -1)
          height = object.get["points"][0].distance object.get["points"][2]

          #将第一面墙填上
          wall_layer = House.room.get["id"] + wall1.get["id"]
          House.model.active_layer = layers[wall_layer]
          plane = [wall1.get["outter_points"][0],wall1.get["normal_vector"]]  #外墙面
          point1 = object.get["points"][2].project_to_plane plane
          point2 = object.get["points"][2].project_to_plane plane_1
          point3 = Geom::Point3d.new(wall1.get["inner_points"][1].x,wall1.get["inner_points"][1].y,wall1.get["inner_points"][1].z)
          point3.z = point1.z
          point4 = [wall1.get["outter_points"][1].x,wall1.get["outter_points"][1].y,wall1.get["outter_points"][1].z]
          point4.z = point1.z
          face1 = a_entities.add_face point1,point2,point3,point4
          if face1.normal.angle_between(base_vec) < 0.1
            face1 .reverse!
          end
          face1.pushpull height
          wall_material1 = materials["material1"]
          wall_material2 = materials["material2"]
          entity1 = face1.all_connected
          iface = ""
          entity1.each{ |e|
            # puts e.typename
            if e.typename == "Face"
              e.material = wall_material1
              e.back_material = wall_material2
              if e.normal.reverse.angle_between(wall1.get["normal_vector"]) < 0.1
                iface = e
              end
            end
          }
          iface.material = wall_material2
          iface.back_material = wall_material1
          entity1 = a_entities.add_group face1.all_connected
          wall_entity = wall1.get["su_model"].get["entity"]
          result = entity1.union(wall_entity)
          result.set_attribute "house_mobject","id",wall1.get["id"]
          result.set_attribute "house_mobject","type","wall"
          wall1.get["su_model"].set_entity(result)

          #将第二面墙填上
          wall_layer = House.room.get["id"] + wall2.get["id"]
          House.model.active_layer = layers[wall_layer]
          plane = [wall2.get["outter_points"][0],wall2.get["normal_vector"]]  #外墙面
          point1 = object.get["points"][1].project_to_plane plane
          point2 = object.get["points"][1].project_to_plane plane_2
          point3 = Geom::Point3d.new(wall2.get["inner_points"][0].x,wall2.get["inner_points"][0].y,wall2.get["inner_points"][0].z)
          point3.z = point1.z
          point4 = [wall2.get["outter_points"][0].x,wall2.get["outter_points"][0].y,wall2.get["outter_points"][0].z]
          point4.z = point1.z
          face2 = a_entities.add_face point1,point2,point3,point4
          if face2.normal.angle_between(base_vec) < 0.1
            face2 .reverse!
          end
          face2.pushpull height
          entity2 = face2.all_connected
          iface = ""
          entity2.each{ |e|
            # puts e.typename
            if e.typename == "Face"
              e.material = wall_material1
              e.back_material = wall_material2
              if e.normal.reverse.angle_between(wall2.get["normal_vector"]) < 0.1
                iface = e
              end
            end
          }
          iface.material = wall_material2
          iface.back_material = wall_material1
          entity2 = a_entities.add_group face2.all_connected
          wall_entity = wall2.get["su_model"].get["entity"]
          result = entity2.union(wall_entity)
          result.set_attribute "house_mobject","id",wall2.get["id"]
          result.set_attribute "house_mobject","type","wall"
          wall2.get["su_model"].set_entity(result)
        else
          points = []
          #门厚度与墙相同
          point1 = object.get["points"][0]
          point2 = object.get["points"][1]
          point3 = [point1.x,point1.y,point2.z]
          point4 = [point2.x,point2.y,point1.z]
          points.push(point1)
          points.push(point3)
          points.push(point2)
          points.push(point4)
          m = object.get["wid"].to_i - 1
          wall = walls[m]
          wall_layer = House.room.get["id"] + wall.get["id"]
          layer = layers[wall_layer]
          House.model.active_layer = layer

          wall_vector = wall.get["normal_vector"]
          wall_vector.normalize!
          # puts door_point1,door_point4,door_point2,door_point3
          thickness = wall.get["thickness"]
          face = a_entities.add_face points
          vector = face.normal
          vector.normalize!
          # puts door_vector.angle_between(wall_vector)
          if vector.angle_between(wall_vector) > 1.57
            face.reverse!
          end
          # puts door_vector.angle_between(wall_vector)
          wall_material1 = materials["material1"]
          wall_material2 = materials["material2"]
          face.pushpull thickness
          dg = face.all_connected
          dg.each{ |e|
            # puts e.typename
            if e.typename == "Face"
              e.material = wall_material1
              e.back_material = wall_material2
            end
          }
          face.material = wall_material2
          face.back_material = wall_material1
          entity = a_entities.add_group face.all_connected

          wall_entity = wall.get["su_model"].get["entity"]
          result = entity.union(wall_entity)
          result.set_attribute "house_mobject","id",wall.get["id"]
          result.set_attribute "house_mobject","type","wall"
          wall.get["su_model"].set_entity(result)
        end
      end

      def get
        return @used_to_return
      end
    end

    # class CHouse
    #   def initialize
    #     @attribute = {}
    #   end

    #   def method_missing(name,*arg)
    #     attribute = name.to_s
    #     if attribute =~ /=$/
    #       @attribute[attribute.chop] = arg[0]
    #     else
    #       @attribute[attribute]
    #     end
    #   end
    # end
  end
end