module BFJO
  module House
  	def self.exception_handle(err)
  		m = err.message
      puts err.backtrace.inspect
  		case m
      when "draw_girder_err"
        girders = House.room.get["mobjects"]["BFJO::House::Girder"]
      	girders.delete_at(girders.size - 1)
      when "draw_column_err"
        columns = House.room.get["mobjects"]["BFJO::House::Column"]
        columns.delete_at(columns.size - 1)
      when "draw_electricity_err"
        electricities = House.room.get["mobjects"]["BFJO::House::Electricity"]
        electricities.delete_at(electricities.size - 1)
      when "draw_window_err"
        windows = House.room.get["mobjects"]["BFJO::House::Window"]
        windows.delete_at(windows.size - 1)
      when "draw_door_err"
        doors = House.room.get["mobjects"]["BFJO::House::Door"]
        doors.delete_at(doors.size - 1)
      when "draw_skirtingline_err"
        skirtingline = House.room.get["mobjects"]["BFJO::House::Skirtingline"]
        skirtingline.delete_at(skirtingline.size - 1)
      when "draw_tripoint_pipe_err"
        tripoint_pipe = House.room.get["mobjects"]["BFJO::House::Tripoint_pipe"]
        tripoint_pipe.delete_at(tripoint_pipe.size - 1)
      when "draw_water_pipe_err"
        water_pipe = House.room.get["mobjects"]["BFJO::House::Water_pipe"]
        water_pipe.delete_at(water_pipe.size - 1)
      when "draw_ceilingline_err"
        ceilingline = House.room.get["mobjects"]["BFJO::House::Ceilingline"]
        ceilingline.delete_at(ceilingline.size - 1)
      when "draw_steps_err"
        steps = House.room.get["mobjects"]["BFJO::House::Steps"]
        steps.delete_at(steps.size - 1)
      # else
      # 	puts "?????????"
      end
  		# UI.messagebox("测量#{House.current_work}时出现异常，请勿回退并重新测量！")
  		state="'[End]测量#{House.measure_name_map[House.current_work]}时出现异常，请勿回退并重新选择测量！'"
  		House.Web.execute_script("show("+"#{state}"+")") #
  		message="'测量#{House.measure_name_map[House.current_work]}时出现异常，请勿回退并重新选择测量！'"
  		House.Web.execute_script("showMessage("+"#{message}"+")")
  		House.Web.canClick = 1
  		House.current_work = ""
  		House.count = 0
      House.Web.execute_script("set_endMeasure_btn_visible("+"#{House.count}"+")")
  	end
  end
end