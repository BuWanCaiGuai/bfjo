/** 
* @param {String} errorMessage  错误信息 
* @param {String} scriptURI   出错的文件 
* @param {Long}  lineNumber   出错代码的行号 
* @param {Long}  columnNumber  出错代码的列号 
* @param {Object} errorObj    错误的详细信息，Anything 
*/
window.onerror = function(errorMessage, scriptURI, lineNumber,columnNumber,errorObj) {
	//如果为语法错误，直接弹窗
	if(errorMessage == '语法错误'){
		var txt = errorMessage + scriptURI + ':'+lineNumber+':'+columnNumber 
					+'\n'+'\n'+
				  '提示：请改正后按F5刷新页面重试！'
		return
	}
 	//自动跳转到error选项卡页面
 	element.tabChange('console', 'error_tab')
  	var errorStack = JSON.stringify(errorObj.stack)
  	//正则表达式不成功，所以采取该方法
  	while(errorStack.indexOf('\\n')>0){
  		errorStack = errorStack.replace('\\n','<br/>')
  	}

    debug(" - 错误信息：" + errorStack)
    return false
}
//debug函数，可以自定义调试提示信息
function debug(msg) {
	var info = document.getElementById('console_error_area')
	info.innerHTML +=msg
	info.innerHTML +='<br/>'
}


//模拟console.log,并输出到界面()
console.log = function() {
	var i = 0
	var length = arguments.length
	var strMsg= ''
	for(;i<length;i++){	
		strMsg = JSON.stringify(arguments[i])
		//如果是字符串就去掉双引号
		if(typeof(arguments[i])=='string')
			strMsg = strMsg.substring(1,strMsg.length-1)		
		strMsg = "<i class='layui-icon' style='font-size:12px;line-height:14px;color:#4876FF;'>&#xe602;</i>"+"&nbsp;"+strMsg
	  	document.getElementById('user_message_area').innerHTML += strMsg
	}
	document.getElementById('user_message_area').innerHTML += '<br>'
}

//清除控制台用户打印的消息
function clear_user_message(){
	document.getElementById('user_message_area').innerHTML = '<button class="console-clear-button" title="Clear console" onclick="clear_user_message()"><i class="layui-icon">&#x1006;</i></button>'
}

//清除控制台错误
function clear_console_error(){
	document.getElementById('console_error_area').innerHTML = '<button class="console-clear-button" title="Clear console" onclick="clear_console_error()"><i class="layui-icon">&#x1006;</i></button>'
}
