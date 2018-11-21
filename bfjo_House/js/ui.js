$(document).ready(
	function() {
		window.location = "skp:scan_lic_file"
		surprise()
		//键盘监听
		$(this).keydown(function(e) {
			if (e.which == "13") {
				if ($("#house_message_div").is(":visible")) {
					$("#confirm_house_btn").click()
				}
				if ($("#room_message_div").is(":visible")) {
					$("#confirm_room_btn").click()
				}
				if ($("#save_message_div").is(":visible")) {
					$("#confirm_save_btn").click()
				}
			}
			//esc被按下
			if (e.which == "27") {
				hide_message()
			}
			//F12被按下
			if (e.which == "123") {
				if ($("#console_area").is(":visible")) {
					$('#console_area').hide()
					//高度自适应
					$("#house_meter_tab").css("height", "auto");
					$("#house_meter_tab").css("overflow-y", "hidden")
				} else {
					$('#console_area').show()
					//指定高度
					$("#house_meter_tab").css("height", "370px")
					$("#house_meter_tab").css("overflow-y", "auto")
				}

			}
		})
		$('.toolbar-button').on('click', function(e) {
			//按钮id的内容
			btnClick = $(this).attr("id")
			//按钮id
			btnId = $('#' + btnClick + '')
			//拥有弹出框的按钮
			if (btnId.hasClass("pop-button"))
				show_input_div()
			else
				do_measure()
			web_get_focus()
		})
		callback("set_html_tag")
	} //function
)


function show_room_tag_edit() {
	$("#add_room_tag_btn").hide()
	$("#edit_room_tag_div").show()
	$("#edit_door_tag_div").hide()
}

function show_door_tag_edit() {
	$("#add_door_tag_btn").hide()
	$("#edit_door_tag_div").show()
	$("#edit_room_tag_div").hide()
}

function setting() {
	$("#cover_div").show()
	//展示房屋信息填写时，
	$("#setting_div").show(10, function() {
		//$('#district_name').focus();
	})
	$("#edit_room_tag_div").hide()
	$("#edit_door_tag_div").hide()
}

//彩蛋：surprise！！！
function surprise() {

	var count = 0,
		timer, isHide = false
	$('#measure_house').on('click', function(e) {
		if (count < 2) {
			if (timer) {
				clearTimeout(timer)
			}
			count++
			timer = setTimeout(function() {
				count = 0;
			}, 500);
		} else if (count === 2) {
			if (!isHide) {
				surprise_shown_btns = []
				surprise_shown_secondry_toolbar = ''
				$('.toolbar-button').each(function() {
					if ($(this).is(':hidden')) {
						$(this).show()
					} else {
						surprise_shown_btns.push($(this).attr("id"))
					}
				})
				$('.secondary-plane').each(function() {
					if ($(this).is(':hidden')) {
						$(this).show()
					} else {
						if (typeof($(this).attr("id")) != "undefined") {
							surprise_shown_secondry_toolbar = $(this).attr("id")
						}
					}
				})
			} else {
				$('.toolbar-button').each(function() {
					if (!$(this).is(':hidden')) {
						$(this).hide()
					}
				})
				$('.secondary-plane').each(function() {
					if (!$(this).is(':hidden')) {
						$(this).hide()
					}
				})
				var i = 0
				var length = surprise_shown_btns.length
				for (; i < length; i++) {
					document.getElementById(surprise_shown_btns[i]).style.display = "inline"
				}
				if (surprise_shown_secondry_toolbar.length != 0)
					document.getElementById(surprise_shown_secondry_toolbar).style.display = "inline"
			}
			isHide = !isHide
			count = 0
			clearTimeout(timer)
		}
	})
}
//add(a,b)
//params：['函数名'，1,2]
function callback(params) {
	window.location = "skp:callback@" + params
}
/*
 *	网页获取焦点
 */
function web_get_focus() {
	//网页获取焦点
	$('#record_field').click()
	$('#record_field').focus()
}
//显示消息弹出框
function show_input_div() {
	switch (btnClick) {
		//管理
		case 'create_house_btn':
			$("#cover_div").show()
			//展示房屋信息填写时，
			$("#house_message_div").show(10, function() {
				$('#district_name').focus();
			})

			break

			//保存
		case 'save_btn':
			$("#cover_div").show()

			$("#save_message_div").show(10, function() {
				$("#save_file_name").focus()
			})


			break

			//新增房间
		case 'add_room_btn':
			$("#cover_div").show()
			$("#room_message_div").show()
			break

		default:
			break
	} //switch
}

//执行
function do_measure() {
	if (inArray(btnClick, measure_object_btns)) {
		var canMeasure = getCanClick(0)
		if (canMeasure) {
			callback(measure_object_callback_map[btnClick])

		} else {
			//测量方式按钮
			if (inArray(btnClick, secondary_toolbar_btns)) {
				warning("已开始测量,不能切换测量方式！")
				return
			} else {
				var current_work = $('#current_work').html()
				if (current_work != '暂无') {
					warning("当前正在进行测量" + current_work)
					return
				}
			}
		}
	} else {
		//以下按钮是否可按由回调函数返回,先设置按钮不可按即canClick=0
		callback("resetCanClick")
		var canDo = false
		//单功能按钮组，封闭墙面按钮
		if (inArray(btnClick, singleFunction_btns)) {
			callback(singlefunction_btn_callback_map[btnClick])
			canDo = getCanClick(1)
			//多功能按钮组，暂停/继续，透明/不透明
		} else if (inArray(btnClick, multifunction_btns)) {

			var state = get_btn_map_state(btnClick)
			if (state)
				callback(multifunction_btn_callback_map[btnClick][1])
			else
				callback(multifunction_btn_callback_map[btnClick][0])
			canDo = getCanClick(1)

		}
		if (!canDo)
			return
	}
	show_clickedBtn()
} //do_measure

//显示停止测量按钮
function set_endMeasure_btn_visible(count) {
	if (count != 0) {
		$("#end_measure_btn").hide()
	} else {
		$("#end_measure_btn").show()
	}
}


//门测量完成后显示门的类型选择信息
function show_door_type() {
	$("#cover_div").show()
	$("#door_message_div").show()
}

function add_cross_cline_tag() {
	$("#cover_div").show()
	$("#cross_cline_tag_div").show()
}
//输入水管直径
function enter_water_pipe_radius() {
	$("#cover_div").show()
	$("#water_pipe_radius_div").show(10, function() {
		$("#water_pipe_radius").focus()
	})
}

//输入插座开关数目
function enter_electricity_num() {
	$("#cover_div").show()
	// $("#water_pipe_radius_div").show()
	// $("#water_pipe_radius_div").show()
	// alert("1111111")
	$("#electricity_num_div").show(10, function() {
		$("#electricity_num").focus()
	})
}

//提交房屋的填写信息
function submit_house_info() {
	var house_attr = [
		$("#district_name").val(),
		$("#building").val(),
		$("#room_no").val()
	]
	if (house_attr[0] == '') {
		warning("小区名称不能为空！")
		$("#district_name").focus()
	} else
	if (house_attr[1] == '') {
		warning("门栋不能为空！")
		$("#building").focus()
	} else
	if (house_attr[2] == '') {
		warning("房号不能为空！")
		$("#room_no").focus()
	} else {
		//确认创建屋子：	
		$("#house_message_div").hide()
		message = ''
		show_hidden_btn(message, 0)
		hide_message()
		show_house_info(house_attr)
		house_attr.unshift("create_house")
		callback(house_attr)
		//如果之前存有房间数据
		if (rooms.length != 0) {
			//清空tabs面板
			for (i = 0; i < rooms.length; i++) {
				element.tabDelete('room_tabs', rooms[i])
			}
			//清空原有房间数据
			rooms = []
			//新添默认面板
			create_room_tab('请添加待测房间')
		}
		hide_message()
		show_clickedBtn()
	}
}
//新建房屋后展示信息：小区，门栋，房号
function show_house_info(house_attr) {
	if (typeof(house_attr) == "string") {
		house_attr = rubyArray_to_jsArray(house_attr)
	}
	$('#house_info').html(house_attr[0] + '小区_' + house_attr[1] + '门栋_' + house_attr[2] + '房')
	$('#house_info_div').show()
}
//当从Sketchup删除房间时，删除对应的的tab页面
function delete_room_from_ruby(deleted_room_name) {
	element.tabDelete('room_tabs', deleted_room_name)
	//rooms数组中移除room数据
	removeByValue(rooms, deleted_room_name)
	if (rooms.length == 0) {
		//新添默认面板
		create_room_tab('请添加待测房间')
	}
	//更新界面
	element.render('tab', 'room_tabs')
}
//从数组中删除指定元素
function removeByValue(arr, val) {
	for (var i = 0; i < arr.length; i++) {
		if (arr[i] == val) {
			arr.splice(i, 1);
			break;
		}
	}
}
//ruby传来的数组在js中会变成字符串，需要转换
function rubyArray_to_jsArray(rubyArray) {
	var rubyStrLength = rubyArray.length
	if (rubyStrLength >= 1) {
		rubyArray = rubyArray.substring(1, rubyStrLength - 2)
		rubyArray = rubyArray.replace(/\"/g, "")
		return rubyArray.split(",")
	}
	return []
}
//提交房间的填写信息
function submit_room_info() {
	var isDisabled = $("#confirm_room_btn").hasClass("disable-confirm-button")
	if (isDisabled) {
		//如果处于不可点击状态
		return
	}
	callback("resetCanClick")
	var room_type = []
	room_type[0] = "create_room"
	room_type[1] = $("#select_room_type option:selected").html()
	callback(room_type)
	$("#set_origin_info").show()
	$("#room_origin_cover_layer").show()
	var canDo = false
	canDo = getCanClick(1)
	if (canDo) {
		$("#confirm_room_btn").addClass("disable-confirm-button")
		//默认第一个被选中
		$("#select_room_type option:first").prop("selected", 'selected')
		render()
		show_clickedBtn()
		hide_message()
	}
}
/**
 *	采用了layui框架，凡是需要重新渲染页面，需要执行layui的render函数
 *	layui网址：http://www.layui.com/doc/modules/form.html#render
 */
function render() {
	var form = layui.form
	form.render()
}
//确认保存
function submit_save() {
	var type = $("#select_save_type option:selected").val()
	var save_type = ''
	switch (type) {
		case '0':
			save_type = 'dbj'
			break
		case '1':
			save_type = 'skp'
			break
		case '2':
			save_type = 'datafile'
			break
		default:
			break
	}

	// save_file_name = $('#save_file_name').val()
	// if(save_file_name.length == 0 ){
	// 	warning("文件名不能为空！")
	// 	$("#save_file_name").focus()
	// 	return
	// }
	callback("resetCanClick")
	var params = []
	params[0] = 'save'
	params[1] = save_type
	callback(params)
	var canDo = false
	canDo = getCanClick(1)
	if (canDo)
		show_clickedBtn()
}
//提交门的信息
function submit_door_info() {
	var isDisabled = $("#confirm_door_btn").hasClass("disable-confirm-button")
	if (isDisabled) {
		//如果处于不可点击状态
		return
	}
	var door_type = $("#select_door_type option:selected").html()
	var params = []
	params[0] = "add_door_tag"
	params[1] = door_type
	callback(params)
	hide_message()
	$("#confirm_door_btn").addClass("disable-confirm-button")
	//默认第一个被选中
	$("#select_door_type option:first").prop("selected", 'selected')
	render()
}

//提交十字虚线标签
function submit_cross_cline_tag_info() {
	if ($("#cross_cline_tag").val() == '') {
		warning("直径不能为空")
		$("#cross_cline_tag").focus()
	} else {
		hide_message()
		var params = []
		params[0] = "get_cross_cline_tag"
		params[1] = $("#cross_cline_tag").val()
		callback(params)
	}
}

//提交水管的直径信息
function submit_water_pipe_info() {
	var regu = /^\d+(\.\d+)?$/
	if (regu.test($("#water_pipe_radius").val())) {
		hide_message()
		var params = []
		params[0] = "get_water_pipe_radius"
		params[1] = $("#water_pipe_radius").val()
		callback(params)
	} else if ($("#water_pipe_radius").val() == '') {
		warning("直径不能为空")
		$("#water_pipe_radius").focus()
	} else {
		warning("直径填写不正确")
		$("#water_pipe_radius").focus()
	}
}

//提交水管的直径信息
function submit_electricity_num() {
	var regu = /^\d+(\.\d+)?$/
	if (regu.test($("#electricity_num").val())) {
		hide_message()
		var params = []
		params[0] = "draw_multi_electricity"
		params[1] = $("#electricity_num").val()
		callback(params)
	} else if ($("#electricity_num").val() == '') {
		warning("数目不能为空")
		$("#electricity_num").focus()
	} else {
		warning("数目填写不正确")
		$("#electricity_num").focus()
	}
}

//隐藏弹出框填写信息
function hide_message() {
	$("#house_message_div").hide()
	$("#room_message_div").hide()
	$("#cover_div").hide()
	$("#door_message_div").hide()
	$("#water_pipe_radius_div").hide()
	$("#electricity_num_div").hide()
	$("#save_message_div").hide()
	$("#cross_cline_tag_div").hide()
	$("#setting_div").hide()
}

//显示当前所选按钮:加边框
function show_clickedBtn() {

	//从ruby中获取并设置当前工作
	var params = "setCurrentWork"
	callback(params)

	//开始测量
	if (btnClick == 'start_measure_btn') {
		message = ''
		show_hidden_btn(message, 2)
		hide_shown_component(0)
	}

	//结束测量
	if (btnClick == 'end_measure_btn') {
		is_measure_end = true
		reset()
		return
	}

	//暂停按钮
	if (btnClick == 'pause_btn') {
		//如果目前是暂停
		if (isPause) {
			shown_btns_when_pause = []
			shown_secondry_toolbar_when_pause = ''
			btnId.css("background-image", "url('images/continue.png')")
			btnId.attr("title", "继续")
			var work = $('#current_work').val()
			$('#current_work').val('[暂停]' + work)
			$('.toolbar-button').each(function() {
				if (!$(this).is(':hidden') && $(this).attr("id") != 'pause_btn' && $(this).attr("id") != 'reconnect_btn') { //20180808xuyang
					shown_btns_when_pause.push($(this).attr("id"))
					$(this).hide()
				}
			})

			$('#reconnect_btn').show() //20180808xuyang

			$('.secondary-plane').each(function() {
				if (!$(this).is(':hidden')) {
					shown_secondry_toolbar_when_pause = $(this).attr("id")
					$(this).hide()
				}
			})
		} else {
			btnId.css("background-image", "url('images/pause.png')")
			btnId.attr("title", "暂停")
			var i = 0
			var length = shown_btns_when_pause.length
			for (; i < length; i++) {
				document.getElementById(shown_btns_when_pause[i]).style.display = "inline"
				//$('#'+shown_btns_when_pause[i]+'').show()
			}

			$('#reconnect_btn').hide() //20180808xuyang

			if (shown_secondry_toolbar_when_pause.length != 0)
				document.getElementById(shown_secondry_toolbar_when_pause).style.display = "inline"
			//$('#'+shown_secondry_toolbar_when_pause+'').show()		
		}
		isPause = !isPause
		//返回
		return
	}
	if (btnClick == 'combine_room_btn') {
		return
	}
	//PS:下次要把三个按钮的代码合为一段

	if (btnClick === 'transparent_btn') {
		//透明状态
		if (isTransparent) {
			btnId.css("background-image", "url('images/transparent.png')")
			btnId.attr("title", "透明")
		}
		//非透明状态
		else {
			btnId.css("background-image", "url('images/opaque.png')")
			btnId.attr("title", "不透明")
		}
		isTransparent = !isTransparent
		return
	}
	if (btnClick == 'set_label_visibility_btn') {

		//根据title获取当前的显示形状
		var title = btnId.attr("title")
		if (title == "隐藏标签") {
			btnId.css("background-image", "url('images/label_shown.png')")
			btnId.attr("title", "显示标签")
		} else {
			btnId.css("background-image", "url('images/label_hidden.png')")
			btnId.attr("title", "隐藏标签")
		}
		return
	}
	if (btnClick == 'set_electric_visibility_btn') {
		//根据title获取当前的显示形状
		var title = btnId.attr("title")
		if (title == "隐藏电器") {
			btnId.css("background-image", "url('images/electric_shown.png')")
			btnId.attr("title", "显示电器")
		} else {
			btnId.css("background-image", "url('images/electric_hidden.png')")
			btnId.attr("title", "隐藏电器")
		}
		return
	}
	//两次按下内容相同，需要放在暂停按钮代码后面，以免不执行暂停按钮代码
	if (lastBtn == btnClick) {
		return
	}
	//标注尺寸按钮
	if (btnClick == 'dimension_btn') {
		if (isRoomDimensioning) {
			btnId.css("background-image", "url('images/roomDimension_hide.png')")
			btnId.attr("title", "隐藏房屋尺寸")
		} else {
			btnId.css("background-image", "url('images/roomDimension.png')")
			btnId.attr("title", "标注房屋尺寸")
		}
		btnId.addClass("button-clicked")
		isRoomDimensioning = !isRoomDimensioning
		return
	} //xuyang17826

	//标注聚焦墙面的尺寸
	if (btnClick == 'dimension_focusedWall_btn') {
		if (isFocusDimensioning) {
			btnId.css("background-image", "url('images/secondary/focus/focusDimension_hide.png')")
			btnId.attr("title", "隐藏墙面尺寸")
		} else {
			btnId.css("background-image", "url('images/secondary/focus/focusDimension.png')")
			btnId.attr("title", "标注墙面尺寸")
		}
		btnId.addClass("button-clicked")
		isFocusDimensioning = !isFocusDimensioning
		return
	} //xuyang17826

	//聚焦墙面
	if (btnClick == 'focus_wallFace_btn') {
		if (isFocusWall) {
			btnId.css("background-image", "url('images/eye_close.png')")
			btnId.attr("title", "恢复视图")
		} else {
			btnId.css("background-image", "url('images/eye.png')")
			btnId.attr("title", "聚焦墙")
			hide_secondary_toolbar()
		}
		btnId.addClass("button-clicked")
		isFocusWall = !isFocusWall
		return
	}
	//如果为包含2级按钮的一级按钮
	if (inArray(btnClick, first_level_btns_with_subBtns)) {
		if (lastBtn != '')
			lastBtnId.removeClass("button-clicked")
		//展示二级按钮
		show_secondary_toolbar()
		//默认测量方式
		var default_btn_id = $('#' + default_measure_btn_map[btnClick] + '')
		default_btn_id.addClass("button-clicked")
		//测墙按钮
		if (btnClick == 'measure_wall_btn') {
			var params = []
			params[0] = "send_wall_thickness"
			callback(params)
			$('#wall_thickness').focus()
		}
	} else {
		//为二级按钮
		if (inArray(btnClick, secondary_toolbar_btns)) {
			opposeBtnRemoveClass(btnClick)
			btnId.addClass("button-clicked")
		}
		//为不包含2级按钮的一级按钮
		else {
			hide_secondary_toolbar()
			btnId.addClass("button-clicked")
			if (lastBtn != '')
				lastBtnId.removeClass("button-clicked")
		}
	}
	if (inArray(btnClick, can_repeated_click_btns)) {
		//可重复点击按钮
		btnId.attr("disabled", false)
	}
	lastBtnId = btnId
	lastBtn = btnClick


}
//从ruby中得到按钮是否为可按状态
function getCanClick_fromRuby(canClick) {
	if (canClick == '0')
		btnCanClick = false
	else
		btnCanClick = true
}
//得到按钮是否为可按状态
function getCanClick(type) {
	var params = []
	params[0] = "getCanClick"
	params[1] = type
	callback(params)
	return btnCanClick
}

//显示二级toolbar
function show_secondary_toolbar() {
	var toolbar_id = $('#' + btnToolbarMap[btnClick] + '')
	//判断二级toolbar是否为空 如若不为空，先隐藏上先前的二级toolbar
	if (secondary_toolbar != '') {
		secondary_toolbar.hide()
		toolbar_id.show()
		secondary_toolbar = toolbar_id
	}
	//为空，直接显示当前二级toolbar
	else {
		toolbar_id.show()
		secondary_toolbar = toolbar_id
	}
}
//隐藏二级toolbar
function hide_secondary_toolbar() {
	//判断二级toolbar是否为空 如若不为空，则直接隐藏
	if (secondary_toolbar != '') {
		secondary_toolbar.hide()
		secondary_toolbar = ''
	}
}
//返回按钮btnTmp是否在按钮组btns里
function inArray(btnTmp, btns) {
	for (var i = 0; i < btns.length; i++) {
		if (btns[i] == btnTmp) {
			return true
		}
	}
	return false
}
//警告信息
function warning(message) {
	var $ = layui.jquery,
		layer = layui.layer; //独立版的layer无需执行这一句
	//初体验
	layer.open({
		type: 1,
		offset: 'rt'
			// ,offset: ['5px']
			,
		content: '<div style="padding: 20px 20px;">' + message + '</div>'
			// ,btn: '关闭全部'
			// ,btnAlign: 'c' //按钮居中
			,
		shade: 0 //不显示遮罩
			,
		area: '200px;',
		time: 1500,
		skin: 'warn'
	});
}
//设置墙的厚度
function setWallthickness() {
	var params = []
	params[0] = "set_wall_thickness"
	params[1] = $("#wall_thickness").val()
	callback(params)
}
//提示消息
function showMessage(message) {

	// layui.use('layer', function(){ //独立版的layer无需执行这一句
	var $ = layui.jquery,
		layer = layui.layer; //独立版的layer无需执行这一句
	//初体验
	layer.open({
		type: 1,
		offset: 'rt'
			// ,offset: ['5px']
			,
		content: '<div style="padding: 20px 20px;">' + message + '</div>'
			// ,btn: '关闭全部'
			// ,btnAlign: 'c' //按钮居中
			,
		shade: 0 //不显示遮罩
			,
		area: '200px;',
		time: 1800

	});

	// })
}
/*设置当前工作*/
function setCurrentWork(work) {
	if (work == '') {
		work = '暂无'
	}
	$('#current_work').html(work)
}
// //得到墙厚初始值，从ruby
// function get_wall_initialThickness(thickness){
// 	var length=thickness.length
// 	$('#wall_thickness').val(thickness.substring(0,length-2))
// }
//得到墙厚，从ruby
function get_wall_thickness(thickness) {
	var length = thickness.length
	$('#wall_thickness').val(thickness.substring(0, length - 2))
}
//二级对立按钮removeClass
function opposeBtnRemoveClass(btn) {
	var index = 0
	for (var i = 0; i < secondaryBtnArray.length; i++) {
		if (inArray(btn, secondaryBtnArray[i])) {
			index = i
			break
		}
	}
	for (var j = 0; j < secondaryBtnArray[index].length; j++) {
		if (btn != secondaryBtnArray[index][j]) {
			var btnOpposeId = $('#' + secondaryBtnArray[index][j] + '')
			btnOpposeId.removeClass("button-clicked")
		}
	}
}
//展示测量信息：测量操作，测量方式，测量点的坐标
function show(txt) {
	//保存测量记录到数组中
	var params = []
	params[0] = 'save_single_measure_record'
	params[1] = txt
	callback(params)
	var div = document.getElementById('points_record')
	div.innerHTML += txt + '<br/>'
	div.scrollTop = div.scrollHeight

} //show
//结束测量后重置,刷新页面
function reset() {
	if (is_measure_end) {
		hide_btn_after_end()
		show_btn_after_end()
		lastBtnId.attr("disabled", false)
		lastBtnId.removeClass("button-clicked")
	}
	//又重新建了house
	else {
		window.location.reload()
	}

}

function get_serials(txt) {
	var serials = document.getElementById('serials')
	if (serials.innerHTML.length == 0) {
		serials.innerHTML += txt
	} else {
		var serials_js = []
		var serials_ruby = []
		serials_js = serials.innerHTML.split(',')
		serials_ruby = txt.split(',')
		var i = 0
		var len = serials_ruby.length
		for (; i < len; i++) {
			if (serials_js.indexOf(serials_ruby[i]) == -1) {
				serials.innerHTML += "," + serials_ruby[i]
			}
		}
	}

}
/**
 * [show_in_table 将ruby中墙及其附着物的属性传递到html中的表格]
 * @param  {[type]} attr_array [description]
 * @return {[type]}            [description]
 */
function show_in_table(attr_array) {
	$("#wall_table  tr:not(:first)").html("")
	$("#wall_table").append('<tr><td style="font-weight:bolder;width: 30px;">' + '墙' + '</td>' +
		'<td>' + attr_array[0][0] + 'mm</td>' +
		'<td>' + attr_array[0][1] + 'mm</td>' +
		'<td>' + attr_array[0][2] + 'mm</td>' +
		'<td>' + attr_array[0][3] + 'mm</td>' +
		'<td>' + attr_array[0][4] + 'mm</td>' +
		'')
	var door_count = attr_array[1].length
	$("#door_table tr:not(:first)").html("")
	if (door_count == 0) {
		$("#door_table").append('<tr><td colspan=7 style="text-align:center;">无数据</td></tr>')
	} else {
		for (i = 0; i < attr_array[1].length; i++) {
			$("#door_table").append('<tr><td style="font-weight:bolder;width: 30px;">' + '门' + '</td>' +
				'<td>' + attr_array[1][i][0] + 'mm</td>' +
				'<td>' + attr_array[1][i][1] + 'mm</td>' +
				'<td>' + attr_array[1][i][2] + 'mm</td>' +
				'<td>' + attr_array[1][i][3] + 'mm</td>' +
				'<td>' + attr_array[1][i][4] + 'mm</td>' +
				'<td>' + attr_array[1][i][5] + 'mm</td>' +
				'')
		}
	}
	var window_count = attr_array[2].length
	$("#window_table tr:not(:first)").html("")
	if (window_count == 0) {
		$("#window_table").append('<tr><td colspan=7 style="text-align:center;">无数据</td></tr>')
	} else {
		for (i = 0; i < attr_array[2].length; i++) {
			$("#window_table").append('<tr><td style="font-weight:bolder;width: 30px;">' + '窗' + '</td>' +
				'<td>' + attr_array[2][i][0] + 'mm</td>' +
				'<td>' + attr_array[2][i][1] + 'mm</td>' +
				'<td>' + attr_array[2][i][2] + 'mm</td>' +
				'<td>' + attr_array[2][i][3] + 'mm</td>' +
				'<td>' + attr_array[2][i][4] + 'mm</td>' +
				'<td>' + attr_array[2][i][5] + 'mm</td>' +
				'')
		}
	}
	var coulmn_count = attr_array[3].length
	$("#column_girder_table tr:not(:first)").html("")
	if (coulmn_count == 0) {
		$("#column_girder_table").append('<tr><td colspan=7 style="text-align:center;">无柱子数据</td></tr>')
	} else {
		// for (j =1;j<=coulmn_count;j++) {
		// 	document.getElementById('column_girder_table').deleteRow(j)
		// }
		for (i = 0; i < coulmn_count; i++) {
			var column_type = ''
			switch (attr_array[3][i][0]) {
				case 'corner_column':
					column_type = '角柱'
					break
			}
			$("#column_girder_table").append('<tr><td style="font-weight:bolder;width: 30px;">' + '柱' + '</td>' +
				'<td>' + column_type + '</td>' +
				'<td>' + attr_array[3][i][1] + 'mm</td>' +
				'<td>' + attr_array[3][i][2] + 'mm</td>' +
				'<td>' + attr_array[3][i][3] + 'mm</td>' +
				'<td>' + attr_array[3][i][4] + 'mm</td>' +
				'<td>' + attr_array[3][i][5] + 'mm</td>' +
				'')
		}
	}
	var girder_count = attr_array[4].length
	if (girder_count == 0) {
		$("#column_girder_table").append('<tr><td colspan=7 style="text-align:center;">无梁数据</td></tr>')
	} else {
		for (i = 0; i < girder_count; i++) {
			$("#column_girder_table").append('<tr><td style="font-weight:bolder;width: 30px;">' + '梁' + '</td>' +
				'<td>' + attr_array[4][i][0] + '</td>' +
				'<td>' + attr_array[4][i][1] + 'mm</td>' +
				'<td>' + attr_array[4][i][2] + 'mm</td>' +
				'<td>' + attr_array[4][i][3] + 'mm</td>' +
				'<td>' + attr_array[4][i][4] + 'mm</td>' +
				'<td>' + attr_array[4][i][5] + 'mm</td>' +
				'')
		}
	}
}
//显示房高
function set_room_height(height, room_name) {
	$('#' + room_name + '_height' + '').val(height + "毫米")
}
//显示房屋面积
function set_room_area(area, room_name) {
	$('#' + room_name + '_area' + '').val(area + "平方米")
}
//新建房间的对应tab
function create_room_tab(room_name) {
	//开始创建房屋时，删除默认tab
	if (rooms.length == 0) {
		element.tabDelete('room_tabs', 'default_tab')
	}
	if (room_name != '请添加待测房间') {
		element.tabDelete('room_tabs', '请添加待测房间')
		is_default_tab = false
		rooms.push(room_name)
	} else {
		//作用：当su存在多个房间时，同时删除会同时在html页面增加多个默认tab：'请添加待测房间'
		if (!is_default_tab) {
			is_default_tab = true
			$("#room_height_input").text = "未测量"
		} else {
			//如果当前是默认tab，则返回，不需要重新添加
			return
		}
	}
	room_count++
	$('#room_tabs').show()
	//新增一个Tab项
	room_tab_content = '<div>' +
		'<form class="layui-form layui-form-pane" action="">' +
		'<div class="layui-form-item">' +
		'<label class="layui-form-label" style="height: 30px;font-size: 12px;width: 80px;">房高</label>' +
		'<div class="layui-input-inline">' +
		'<input  disabled="disabled" id="' + room_name + '_height' + '" lay-verify="required" placeholder="未测量" autocomplete="off" class="layui-input" type="text" style="height: 30px;font-size: 12px;">' +
		'</div>' +
		'</div>' +
		'<div class="layui-form-item">' +
		'<label class="layui-form-label" style="height: 30px;font-size: 12px;width: 80px;">房屋面积</label>' +
		'<div class="layui-input-inline">' +
		'<input  disabled="disabled" id="' + room_name + '_area' + '" lay-verify="required" placeholder="未测量" autocomplete="off" class="layui-input" type="text" style="height: 30px;font-size: 12px;">' +
		'</div>' +
		'</div>'
	'</form>' +
	'</div>'
	element.tabAdd('room_tabs', {
		title: room_name,
		content: room_tab_content,
		id: room_name //用房屋名称制作tab_id
	})

	//切换到最新测量的房间
	element.tabChange('room_tabs', room_name)
	//更新界面
	//element.render('tab', 'room_tabs')	
}
//显示隐藏的按钮
function show_hidden_btn(message, btn_array_index) {
	btn_array_index = parseInt(btn_array_index)
	//显示接下来的按钮
	var len = hidden_btn[btn_array_index].length
	for (var btn_index = 0; btn_index < len; btn_index++) {

		var btn = $('#' + hidden_btn[btn_array_index][btn_index] + '')
		btn.show()

	}
	//是否提示消息
	if (message != '') {
		showMessage(message)
	}
}
//测量过程中隐藏相关组件
function hide_shown_component(index) {
	var length = hidden_components_during_measure[index].length
	var i = 0
	var component
	for (; i < length; i++) {
		component = $('#' + hidden_components_during_measure[index][i] + '')
		component.hide()
		if (btnToolbarMap.hasOwnProperty(hidden_components_during_measure[index][i]))
			$('#' + btnToolbarMap[hidden_components_during_measure[index][i]] + '').hide()
	}
}
//结束测量后，隐藏相关的按钮
function hide_btn_after_end() {
	hide_secondary_toolbar()
	//隐藏相关按钮
	var len_1 = hidden_btn.length
	for (var i = 1; i < len_1; i++) {
		var len_2 = hidden_btn[i].length
		for (var j = 0; j < len_2; j++) {
			var btn = $('#' + hidden_btn[i][j] + '')
			btn.hide()
		}
	}
}
//结束测量后，展示相关的按钮
function show_btn_after_end() {
	if (room_count >= 2)
		$("#combine_room_btn").show()
	else
		$("#combine_room_btn").hide()
	var length = hidden_components_during_measure[0].length
	var i = 0
	//最后一个为房间拼接按钮
	for (; i < length - 1; i++) {
		//初始按钮
		$('#' + hidden_components_during_measure[0][i] + '').show()
	}
}

function show_combine_room_btn() {
	$("#combine_room_btn").show()
}
//展示测墙按钮，在ruby调用
function show_measure_wall_btn() {
	$("#measure_wall_btn").show()
}
//清屏
function clearShow() {
	$('#points_record').html('');
} //clearShow

function set_door_tag(text_array) { //2018129
	var form = layui.form
	for (var i = 1; i < text_array.length; i++) {
		$("#door_table tbody").append("<tr><td>" + text_array[i] + "</td><td><label>删除</label></td></tr>");
	}
	$("td").find("label").css({
		"color": "red"
	});
	 $("td").find("label").attr("onclick", "javascript:delete_door_type(this);");
	form.render()
}

function set_select_room_tag(text_array) { //2018129
	var form = layui.form
	var obj = document.getElementById('select_room_type');
	for (var i = 0; i < text_array.length; i++) {
		obj.add(new Option(text_array[i], i));
	}
	form.render()
}

function set_select_door_tag(text_array) { //2018129
	var form = layui.form
	var obj = document.getElementById('select_door_type');
	for (var i = 0; i < text_array.length; i++) {
		obj.add(new Option(text_array[i], i));
	}
	form.render()
}

//设置房间的标签
function set_room_tag(text_array) { //2018129
	var form = layui.form
	for (var i = 1; i < text_array.length; i++) {
		$("#room_table tbody").append("<tr><td>" + text_array[i] + "</td><td><p>删除</p></td></tr>");
	}
	$("td").find("p").css({
		"color": "red"
	});
	$("td").find("p").attr("onclick", "javascript:delete_room_type(this);");
	form.render()
}

function delete_room_type(obj) {
	layer.confirm('您确定要删除？', {
		btn: ['确定', '取消'] //按钮
	}, function() {
		var index = $(obj).parents("td").parents("tr").index();
		index++;
		var tlength = $("#room_table>tbody").children("tr").length;
		var tb = document.getElementById('room_table'); // table 的 id
		var rows = tb.rows;
		var params = []
		params[0] = "delete_room_tag"
		params[1] = "请选择"
		callback(params)
		var params1 = []
		params1[0] = "add_room_tag"
		for (var i = 1; i < tlength; i++) {
			if (i!=index) {
				params1[1] = rows[i].cells[0].innerHTML
				callback(params1)
			}
		}
		$(obj).parents("td").parents("tr").remove();
		showMessage('删除成功！')
		var srt = document.getElementById('select_room_type');
		srt.options.length=0;
		callback("update_room_tag")
		layer.closeAll('dialog');

	}, function() {});
}

// var room_type_array = []
// function delete_room_type(obj) {
// 	layer.confirm('您确定要删除？', {
// 		btn: ['确定', '取消'] //按钮
// 	}, function() {
// 		var index = $(obj).parents("td").parents("tr").index()
// 		//要删除的房间类型
// 		var deleting_room_type = $("#room_table tr:eq(" + (index+1) + ") td:eq(0)").html()
// 		//从默认房间数组中删除
// 		removeByValue(room_type_array,deleting_room_type)
// 		var params = []
// 		//更新房间类型文件
// 		params[0] = "update_room_tag_file"
// 		params[1] = room_type_array
// 		callback(params)
// 		var is_deleted = getCanClick(1)
// 		if(is_deleted){
// 			$(obj).parents("tr").remove()
// 			set_select_room_tag(room_type_array)
// 			showMessage('删除成功！')
// 		}else{
// 			//删除失败，还原原来的房间类型数组
// 			room_type_array.push(deleting_room_type)
// 			warning('删除失败！')
// 		}
// 		layer.closeAll('dialog');
// 	}, function() {});
// }

function delete_door_type(obj) {
	layer.confirm('您确定要删除？', {
		btn: ['确定', '取消'] //按钮
	}, function() {
		var index = $(obj).parents("td").parents("tr").index();
		index++;
		
		var tb = document.getElementById('door_table'); // table 的 id
		var rows = tb.rows;
		var params = []
		params[0] = "delete_door_tag"
		params[1] = "请选择"
		callback(params)
		$(obj).parents("td").parents("tr").remove();
		 showMessage('删除成功！')
	    layer.closeAll('dialog');
	    var tlength = $("#door_table>tbody").children("tr").length;
		var params1 = []
		params1[0] = "add_door_tag"
		 for (var i = 1; i < tlength; i++) {
				params1[1] = rows[i].cells[0].innerHTML
				callback(params1)
		}
		var sdt = document.getElementById('select_door_type');
		sdt.options.length=0;
		callback("update_door_tag")
		layer.closeAll('dialog');
	}, function() {});
}

function hide_edit_room_div(){
	$("#edit_room_tag_div").hide()
	$("#add_room_tag_btn").show()
}

function hide_edit_door_div(){
	$("#edit_door_tag_div").hide()
	$("#add_door_tag_btn").show()
}

function submit_new_room_tag() {
	var form = layui.form
	var room_add = $("#edit_room_tag_input").val()
	if (room_add == '') {
		warning("新增的房间类型不能为空！")
	} else {
		var tb = document.getElementById('room_table'); // table 的 id
		var rows = tb.rows;
		for (var i = 1; i < rows.length; i++) {
			if (room_add==rows[i].cells[0].innerHTML) {
				warning("该房间类型已存在！");
				$("#edit_room_tag_input").val('')
				return
			}
		}
		var obj = "<tr><td>" + room_add + "</td><td><p>删除</p></td></tr>"
		$("#room_table tbody").append(obj);
		$("td").find("p").css({
			"color": "red"
		});
		var params1 = []
		params1[0] = "add_room_tag"
		params1[1] = room_add
		callback(params1)
		form.render()
		var srt = document.getElementById('select_room_type');
		srt.options.length=0;
		callback("update_room_tag")
		$("td").find("p").attr("onclick", "javascript:delete_room_type(this);");
		showMessage('添加成功！')
		$("#edit_room_tag_input").val('')
		$("#edit_room_tag_div").hide()
		$("#add_room_tag_btn").show()
	}
}

function submit_new_door_tag() {
	var form = layui.form
	var door_add = $("#edit_door_tag_input").val()
	if (door_add == '') {
		warning("新增的门类型不能为空！")
	} else {
		var tb = document.getElementById('door_table'); // table 的 id
		var rows = tb.rows;
		for (var i = 1; i < rows.length; i++) {
			if (door_add==rows[i].cells[0].innerHTML) {
				warning("该门类型已存在！");
				$("#edit_door_tag_input").val('')
				return
			}
		}
		var obj = "<tr><td>" + door_add + "</td><td><label>删除</label></td></tr>"
		$("#door_table tbody").append(obj);
		$("td").find("label").css({
			"color": "red"
		});
		var params1 = []
		params1[0] = "add_door_tag"
		params1[1] = door_add
		callback(params1)
		form.render()
		var sdt = document.getElementById('select_door_type');
		sdt.options.length=0;
		callback("update_door_tag")
		$("td").find("label").attr("onclick", "javascript:delete_door_type(this);");
		showMessage('添加成功！')
		$("#edit_door_tag_input").val('')
		$("#edit_door_tag_div").hide()
		$("#add_door_tag_btn").show()
	}
}

function setwallcolor(){
	var wall_color = [
		"m00_material",
		$("#wall_r").val(),
		$("#wall_g").val(),
		$("#wall_b").val(),
	]
	// var params = []
	// params[0] = "update_color"
	// params[1] = wall_color
	// callback(params)
	// showMessage("墙颜色设置成功！")
}

function setplanecolor(){
	var plane_color = [
		"plane",
		$("#plane_r").val(),
		$("#plane_g").val(),
		$("#plane_b").val(),
	]
	var params = []
	params[0] = "update_color"
	params[1] = plane_color
	callback(params)
	showMessage("天花板地板颜色设置成功！")
}

function setfloorcolor(){
	var floor_color = [
		"floor",
		$("#floor_r").val(),
		$("#floor_g").val(),
		$("#floor_b").val(),
	]
	var params = []
	params[0] = "update_color"
	params[1] = floor_color
	callback(params)
	showMessage("地板颜色设置成功！")
}

function setinnerwallcolor(){
	var innerwall_color = [
		"innerwall",
		$("#innerwall_r").val(),
		$("#innerwall_g").val(),
		$("#innerwall_b").val(),
	]
	var params = []
	params[0] = "update_color"
	params[1] = innerwall_color
	callback(params)
	showMessage("内墙颜色设置成功！")
}

function setoutterwallcolor(){
	var outterwall_color = [
		"outterwall",
		$("#outterwall_r").val(),
		$("#outterwall_g").val(),
		$("#outterwall_b").val(),
	]
	var params = []
	params[0] = "update_color"
	params[1] = outterwall_color
	callback(params)
	showMessage("外墙颜色设置成功！")
}

function setgirdercolor(){
	var girder_color = [
		"girder",
		$("#girder_r").val(),
		$("#girder_g").val(),
		$("#girder_b").val(),
	]
	var params = []
	params[0] = "update_color"
	params[1] = girder_color
	callback(params)
	showMessage("梁颜色设置成功！")
}

function setcolumncolor(){
	var column_color = [
		"column",
		$("#column_r").val(),
		$("#column_g").val(),
		$("#column_b").val(),
	]
	var params = []
	params[0] = "update_color"
	params[1] = column_color
	callback(params)
	showMessage("柱颜色设置成功！")
}

function setceilinglinecolor(){
	var ceilingline_color = [
		"ceilingline",
		$("#ceilingline_r").val(),
		$("#ceilingline_g").val(),
		$("#ceilingline_b").val(),
	]
	var params = []
	params[0] = "update_color"
	params[1] = ceilingline_color
	callback(params)
	showMessage("石膏线颜色设置成功！")
}

function setskirtinglinecolor(){
	var skirtingline_color = [
		"skirtingline",
		$("#skirtingline_r").val(),
		$("#skirtingline_g").val(),
		$("#skirtingline_b").val(),
	]
	var params = []
	params[0] = "update_color"
	params[1] = skirtingline_color
	callback(params)
	showMessage("踢脚线颜色设置成功！")
}

function add_license() {
	window.location = "skp:add_license"
}

// function reconnect(){ //20180808xuyang
// 	window.location = "skp:reconnect"
// }
//如果序列号过多，会用省略号表示，并且在hover的时候显示全部
function show_serials() {
	var clientWidth = document.getElementById("serials").clientWidth;
	var scrollWidth = document.getElementById("serials").scrollWidth;
	if (clientWidth < scrollWidth) {
		$("#serialsTd").attr("title", document.getElementById("serials").innerHTML);
	}
}
layui.use(['form', 'table', 'element'], function() {
	element = layui.element //导航的hover效果、二级菜单等功能，需要依赖element模块
	form = layui.form
	layer = layui.layer
	//得到当前所选的tab
	element.on('tab(demo)', function(data) {})
	//触发事件
	var active = {

	};

	$('.site-demo-active').on('click', function() {
		var othis = $(this),
			type = othis.data('type');
		active[type] ? active[type].call(this, othis) : '';
	});
	var form = layui.form
	var layer = layui.layer
	var table = layui.table
	//门类型选择select下拉框监听
	form.on('select(door_area)', function(data) {
		//请选择
		if (data.value != '0') {
			$("#confirm_door_btn").removeClass("disable-confirm-button")
		} else {
			$("#confirm_door_btn").addClass("disable-confirm-button")
		}
	})
	//房间类型选择select下拉框监听
	form.on('select(room_area)', function(data) {
		//请选择
		if (data.value != '0') {
			$("#confirm_room_btn").removeClass("disable-confirm-button")
		} else {
			$("#confirm_room_btn").addClass("disable-confirm-button")
		}
	})
	//门类型选择select下拉框监听
	form.on('select(setting_door_area)', function(data) {
		//请选择
		if (data.value != '0') {
			$("#delete_door_tag_btn").removeClass("disable-confirm-button")
		} else {
			$("#delete_door_tag_btn").addClass("disable-confirm-button")
		}
	})

	form.on('select(setting_room_area)', function(data) {
		//请选择
		if (data.value != '0') {
			$("#delete_room_tag_btn").removeClass("disable-confirm-button")
		} else {
			$("#delete_room_tag_btn").addClass("disable-confirm-button")
		}
	})

})



var rooms = []
//分类二级按钮组
var secondaryBtnArray = [
	//测平面方式选择
	['plane_onePoint', 'plane_threePoints'],
	//测门方式
	['door_twoPoints_0', 'door_twoPoints_1', 'door_eightPoints'],
	//测窗方式
	['window_twoPoints', 'window_eightPoints', 'normal_bay_window', 'LType_bay_window'],
	//柱子测量方式
	['corner_column', 'midWall_column', 'midRoom_column'],
	//台阶测量方式
	['steps'],
	//梁测量方式
	['corner_girder', 'midRoom_girder'],
	//水电测量方式:13种
	['socket', 'switch', 'gas_on_wall', 'gas_on_ground', 'drain', 'faucet', 'exhaust', 'electricBox', 'air_conditioning', 'outlet_on_wall', 'outlet_on_ceiling', 'water_intake_wall', 'water_intake_ground', 'tripoint_pipe', 'cross_cline'],

	//聚焦墙面的时候，显示/尺寸
	['dimension_focusedWall_btn']
]
//拥有二级按钮的一级按钮
var first_level_btns_with_subBtns = [
	'plane_option_btn',
	'measure_wall_btn',
	'measure_steps_btn',
	'set_wallthickness_btn',
	'measure_window_btn',
	'measure_door_btn',
	'measure_column_btn',
	'measure_girder_btn',
	'measure_electricity_btn',
	'set_wallthickness_btn',
	'focus_wallFace_btn',
]
//存储按钮的对应的二级toolbar
var btnToolbarMap = {}
btnToolbarMap['plane_option_btn'] = 'plane_toolbar'
btnToolbarMap['measure_wall_btn'] = 'wall-plane'
btnToolbarMap['set_wallthickness_btn'] = 'wall_thickness_form'
btnToolbarMap['measure_window_btn'] = 'window_toolbar'
btnToolbarMap['measure_door_btn'] = 'door_toolbar'
btnToolbarMap['measure_steps_btn'] = 'steps_toolbar'
btnToolbarMap['measure_column_btn'] = 'column_toolbar'
btnToolbarMap['measure_girder_btn'] = 'girder_toolbar'
btnToolbarMap['measure_electricity_btn'] = 'electricity_toolbar'
btnToolbarMap['set_wallthickness_btn'] = 'wall_thickness_resetForm'
btnToolbarMap['focus_wallFace_btn'] = 'dimension_focusedWall_toolbar'

//隐藏的按钮组
var hidden_btn = [
	['add_room_btn', 'setting', 'opaque_btn', 'import_data_btn'], //0创建房屋后显示
	['start_measure_btn', 'undo_btn', 'pause_btn', 'end_measure_btn'], //1增加房间后显示
	['plane_option_btn'], //2
	['measure_wall_btn'], //3
	['end_measure_btn', 'measure_steps_btn', 'measure_window_btn', 'measure_door_btn', 'measure_girder_btn', 'measure_column_btn', 'measure_electricity_btn', 'measure_skirtingline_btn', 'measure_ceilingline_btn',
		'suspended_ceiling_btn'
	] //4
] //20180225
//在测量过程中需要隐藏的组件（按钮或div）
var hidden_components_during_measure = [
	['create_house_btn', 'save_btn', 'import_data_btn', 'clear_model_btn', 'add_room_btn', 'egmenting_line', 'combine_room_btn'], //开始测量后隐藏:0
	['plane_option_btn'], //平面测量结束后
	['measure_wall_btn'], //封闭墙面后
]
//可以重复点击的按钮组
var can_repeated_click_btns = [
	'create_house_btn',
	'save_btn',
	'import_data_btn',
	'focus_wallFace_btn',
	'clear_model_btn',
	'dimension_focusedWall_btn',
	'dimension_btn',
	'combine_room_btn',
	'reconnect_btn', //20180808xuyang
]
//layui的基本元素
var element, form, layer
//房间计数
var room_count = 0
var isFocusWall = true
//是否暂停，是否透明
var isPause = true,
	isTransparent = false
var isRoomDimensioning = true //xuyang170826
var isFocusDimensioning = true //xuyang170826
//存储当前创建的房间名称
var current_room_name = ''
//存储当前二级toolbar
var secondary_toolbar = ''

//二级按钮组
var secondary_toolbar_btns = new Array("plane_onePoint", "plane_threePoints", "door_twoPoints_0", "door_twoPoints_1", "door_eightPoints", "window_twoPoints", "window_eightPoints", "normal_bay_window", "LType_bay_window", 'tripoint_pipe', 'cross_cline',
	"dimension_focusedWall_btn", "corner_column", "midWall_column", "midRoom_column", "corner_girder", "midRoom_girder", 'steps', 'socket', 'switch', 'gas_on_wall', 'gas_on_ground', 'drain', 'water_intake_wall', 'water_intake_ground', 'faucet', 'exhaust', 'electricBox', 'air_conditioning', 'outlet_on_wall', 'outlet_on_ceiling')
//不拥有二级按钮的一级按钮组
var one_toolbarOne_btns = new Array("start_measure_btn", "end_measure_btn", "extend_wall_btn", "dimension_btn")
//记录上一次所按下的按钮
var lastBtnId = ''
var lastBtn = ''
//当前按钮id的内容
var btnClick = ''
//当前按钮id
var btnId = ''
//按钮是否可按
var btnCanClick = false
// 默认选项卡：'请添加待测房间'
var is_default_tab = false
//测量是否结束
var is_measure_end = false
//在暂停的时候显示的按钮
var shown_btns_when_pause = []
//在暂停的时候显示的二级工具栏
var shown_secondry_toolbar_when_pause = ''
//彩蛋
var surprise_shown_btns = []
var surprise_shown_secondry_toolbar = ''
//默认测量对象
var default_measure_btn_map = {}
default_measure_btn_map['plane_option_btn'] = 'plane_onePoint'
default_measure_btn_map['measure_wall_btn'] = 'wall_twoPoints'
default_measure_btn_map['measure_window_btn'] = 'window_twoPoints'
default_measure_btn_map['measure_door_btn'] = 'door_twoPoints_1'
default_measure_btn_map['measure_column_btn'] = 'corner_column'
default_measure_btn_map['measure_girder_btn'] = 'corner_girder'
default_measure_btn_map['measure_steps_btn'] = 'steps'
default_measure_btn_map['measure_electricity_btn'] = 'socket'
//测量对象按钮组
var measure_object_btns = [
	'plane_option_btn', //平面测量
	'plane_onePoint', //平面测量方式：地面一点，天花板一点
	'plane_threePoints', //平面测量方式：地面三点，天花板三点
	'measure_wall_btn', //测量墙面
	'measure_window_btn', //测量窗户
	'window_eightPoints', //测量窗户方式:对角八点
	'window_twoPoints', //测量窗户方式:对角两点
	'normal_bay_window', //测量窗户方式:1字型飘窗
	'LType_bay_window', //测量窗户方式:L型飘窗
	'measure_door_btn', //测量门
	'door_twoPoints_0', //测量门方式：对角两点
	'door_twoPoints_1', //测量门方式：顶一点，对边一点
	'door_eightPoints', //测量门方式：对角八点
	'measure_steps_btn', //台阶测量
	'steps', //台阶测量
	'measure_column_btn', //开始测量柱
	'midWall_column', //墙中柱
	'corner_column', //角柱
	'midRoom_column', //房中柱
	'measure_girder_btn', //梁
	'corner_girder', //角梁
	'midRoom_girder', //房中梁
	'measure_skirtingline_btn', //基脚线
	'measure_ceilingline_btn', //石膏线
	'measure_electricity_btn', //测量水电
	'tripoint_pipe', //三点水管
	'cross_cline', //十字虚线
	'water_intake_ground', //地上进水
	'water_intake_wall', //墙上进水
	'socket', //插座
	'switch', //开关
	'gas_on_wall', //墙上燃气
	'gas_on_ground', //地上燃气
	'drain', //排水
	'faucet', //水龙头
	'exhaust', //排气
	'electricBox', //电箱
	'air_conditioning', //空调
	'outlet_on_wall', //墙出风口
	'outlet_on_ceiling', //天花口出风口
	'suspended_ceiling_btn', //吊顶
]
//测量对象按钮及其对应的回调函数
var measure_object_callback_map = {}
var specific_function_measure_object = "set_count"
measure_object_callback_map['plane_option_btn'] = [specific_function_measure_object, 'plane', '0']
measure_object_callback_map['plane_onePoint'] = [specific_function_measure_object, 'plane', '0']
measure_object_callback_map['plane_threePoints'] = [specific_function_measure_object, 'plane', '1']

measure_object_callback_map['measure_wall_btn'] = [specific_function_measure_object, 'wall', '-1']


measure_object_callback_map['measure_steps_btn'] = [specific_function_measure_object, 'steps', '-1']
measure_object_callback_map['steps'] = [specific_function_measure_object, 'steps', '-1']

measure_object_callback_map['measure_window_btn'] = [specific_function_measure_object, 'window', '1']
measure_object_callback_map['window_eightPoints'] = [specific_function_measure_object, 'window', '0']
measure_object_callback_map['window_twoPoints'] = [specific_function_measure_object, 'window', '1']
measure_object_callback_map['normal_bay_window'] = [specific_function_measure_object, 'window', '2']
measure_object_callback_map['LType_bay_window'] = [specific_function_measure_object, 'window', '3']

measure_object_callback_map['measure_door_btn'] = [specific_function_measure_object, 'door', '2']
measure_object_callback_map['door_twoPoints_0'] = [specific_function_measure_object, 'door', '1']
measure_object_callback_map['door_twoPoints_1'] = [specific_function_measure_object, 'door', '2']
measure_object_callback_map['door_eightPoints'] = [specific_function_measure_object, 'door', '0']

measure_object_callback_map['measure_column_btn'] = [specific_function_measure_object, 'column', '1']
measure_object_callback_map['corner_column'] = [specific_function_measure_object, 'column', '1']
measure_object_callback_map['midWall_column'] = [specific_function_measure_object, 'column', '2']
measure_object_callback_map['midRoom_column'] = [specific_function_measure_object, 'column', '3']

measure_object_callback_map['measure_girder_btn'] = [specific_function_measure_object, 'girder', '1']
measure_object_callback_map['corner_girder'] = [specific_function_measure_object, 'girder', '1']
measure_object_callback_map['midRoom_girder'] = [specific_function_measure_object, 'girder', '2']

measure_object_callback_map['measure_skirtingline_btn'] = [specific_function_measure_object, 'skirtingline', '-1']

measure_object_callback_map['measure_ceilingline_btn'] = [specific_function_measure_object, 'ceilingline', '-1']

measure_object_callback_map['tripoint_pipe'] = [specific_function_measure_object, 'tripoint_pipe', '-1']

measure_object_callback_map['water_intake_ground'] = [specific_function_measure_object, 'water_pipe', '1']
measure_object_callback_map['water_intake_wall'] = [specific_function_measure_object, 'water_pipe', '2']

measure_object_callback_map['measure_electricity_btn'] = [specific_function_measure_object, 'electricity', '0']
measure_object_callback_map['socket'] = [specific_function_measure_object, 'electricity', '0']
measure_object_callback_map['switch'] = [specific_function_measure_object, 'electricity', '1']
measure_object_callback_map['gas_on_wall'] = [specific_function_measure_object, 'electricity', '2']
measure_object_callback_map['gas_on_ground'] = [specific_function_measure_object, 'electricity', '3']
measure_object_callback_map['drain'] = [specific_function_measure_object, 'electricity', '4']
measure_object_callback_map['faucet'] = [specific_function_measure_object, 'electricity', '5']
measure_object_callback_map['exhaust'] = [specific_function_measure_object, 'electricity', '6']
measure_object_callback_map['electricBox'] = [specific_function_measure_object, 'electricity', '7']
measure_object_callback_map['air_conditioning'] = [specific_function_measure_object, 'electricity', '8']
measure_object_callback_map['outlet_on_wall'] = [specific_function_measure_object, 'electricity', '9']
measure_object_callback_map['outlet_on_ceiling'] = [specific_function_measure_object, 'electricity', '10']
measure_object_callback_map['cross_cline'] = [specific_function_measure_object, 'electricity', '11']


//吊顶
measure_object_callback_map['suspended_ceiling_btn'] = [specific_function_measure_object, 'suspended_ceiling', '-1']

//单功能非测量对象按钮组
var singleFunction_btns = [
	'start_measure_btn', //开始测量
	'import_data_btn', //导入数据
	'clear_model_btn', //清除测量的房屋
	'undo_btn', //回退
	'end_measure_btn', //结束测量
	'extend_wall_btn', //封闭墙面
	'direct_enclose_wall_btn', //直接封闭墙面
	'dimension_btn', //标注尺寸
	'focus_wallFace_btn', //墙面聚焦
	'dimension_focusedWall_btn', //聚焦时，尺寸显示，隐藏
	'combine_room_btn', //房间拼接
	'hide_dimensions_btn', //隐藏全部尺寸
	'reconnect_btn', //重新连接测量仪 20180808xuyang

]
//单功能非测量对象按钮对应的回调函数
var singlefunction_btn_callback_map = {}

singlefunction_btn_callback_map['start_measure_btn'] = 'start_measure'
singlefunction_btn_callback_map['import_data_btn'] = 'redraw_model'
singlefunction_btn_callback_map['clear_model_btn'] = "clear_model"
singlefunction_btn_callback_map['undo_btn'] = "undo"
singlefunction_btn_callback_map['end_measure_btn'] = 'end_measure'
singlefunction_btn_callback_map['extend_wall_btn'] = ['encircle', 0]
singlefunction_btn_callback_map['direct_enclose_wall_btn'] = ['encircle', 1]
singlefunction_btn_callback_map['dimension_btn'] = "dimensioning"
singlefunction_btn_callback_map['focus_wallFace_btn'] = 'focus_wallFace'
singlefunction_btn_callback_map['dimension_focusedWall_btn'] = 'dimension_focused_wall'
singlefunction_btn_callback_map['combine_room_btn'] = 'start_combine_room'
singlefunction_btn_callback_map['hide_dimensions_btn'] = 'hide_all_dimension'
singlefunction_btn_callback_map['reconnect_btn'] = 'reconnect' //20180808xuyang



//多功能按钮组
var multifunction_btns = [
	'pause_btn', //暂停继续按钮
	'transparent_btn', //透明与非透明设置按钮
	'set_label_visibility_btn', //显示与隐藏标签
	'set_electric_visibility_btn', //显示与隐藏电器
	'set_dimensions_btn', //标注与隐藏尺寸
]
//多功能按钮对应的回调函数
var multifunction_btn_callback_map = {}
multifunction_btn_callback_map['pause_btn'] = ['continue_measure', 'pause_measure']


multifunction_btn_callback_map['transparent_btn'] = ['set_transparency', 'set_opaque']


multifunction_btn_callback_map['set_label_visibility_btn'] = ['set_tag_visible']

multifunction_btn_callback_map['set_electric_visibility_btn'] = ['set_electricity_visible']

multifunction_btn_callback_map['set_dimensions_btn'] = ['show_selected_dim']

//得到多功能按钮所对应的当前状态值
function get_btn_map_state(btn) {
	//暂停
	if (btn == 'pause_btn')
		return isPause
	else
	if (btn == 'transparent_btn')
		return isTransparent
	else
		return false
}