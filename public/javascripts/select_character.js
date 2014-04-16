$(document).ready(function(){
	var active_character;
	$('.select_character_div').click(function(){
		active_character = $(this).find('.character_id').attr('id');
		$(this).addClass('highlight');
	});
	
	$('#play_button').click(function(){
		var o = {"active_character": active_character};
		select_char(o);
	});
});

function select_char(o){
	var form;
	form = $('<form />', {
		action: '/select_character',
		method: 'POST',
		style: 'display: none;'
	});
	$('<input />', {
		type: 'hidden',
		name: 'character',
		value: o.active_character
	}).appendTo(form);
	form.appendTo('body').submit();
}