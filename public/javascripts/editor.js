$(document).ready(function(){
	//current tile  variables
	var current_tile_id;
	var current_tile_background;
	var current_tile_background_position;


	var active_layer = '#layer1';
	var layer_toggle = $("#layer_toggle");
	var layer_tiles_pane = $("#layer_tiles_pane");
	var layer_pane = $("#layer_pane");
	var previous_active;
	$('#close_layers').click(function(e){
		e.preventDefault();
		previous_active.children('a').tab('show');
		$(this).parent().removeClass('active');
		layer_tiles_pane.removeClass('show');
		layer_tiles_pane.addClass('hidden');
		layer_pane.removeClass('col-sm-8');
		layer_pane.addClass('col-sm-12');
		layer_toggle.text('Show Layers/Tiles');
	});
	$('#left_tabs a').click(function(e){
		e.preventDefault();
		if($(this).attr('id') == 'layer_toggle'){
			previous_active = $('#left_tabs').find('.active');
			layer_toggle.text('Hide Layers/Tiles');
			layer_tiles_pane.removeClass('hidden');
			layer_tiles_pane.addClass('show');
			layer_pane.removeClass('col-sm-12');
			layer_pane.addClass('col-sm-8');
			$(this).tab('show');
		} else {
			$('#layer_name').val('');
			active_layer = $(this).attr('href');
			$('.layer_tiles').hide();
			var layer_tiles = active_layer.substring(1);
			$('.' + layer_tiles + '_tiles').show();
		}
	});
	
	$('.available_thumbnail').click(function(){
		current_tile_id = $(this).attr('id');
		current_tile_background = $(this).css('background-image');
		current_tile_background_position = $(this).css('background-position');
		$('#current_tile').css('background-image',current_tile_background).css('background-position',current_tile_background_position);
	});
	
	$('.tile_spot').click(function(){
		$(this).attr('tid',current_tile_id);
		$(this).css('background',current_tile_background);
		$(this).css('background-position',current_tile_background_position);
	});
	
	$('.save_layer_btn').click(function(){
		save_layer(active_layer,$(this).prev().find('input').val());
	});
	
	var active_map = 0;
	//selected layers for a map
	var map_layer1 = 0;
	var map_layer2 = 0;
	var map_layer3 = 0;
	var map_layer4 = 0;
	var map_layer5 = 0;
	var map_layer6 = 0;
	
	$('.layer1').click(function(){
		map_layer1 = $(this).attr('lid');
	});
	$('.layer2').click(function(){
		map_layer2 = $(this).attr('lid');
	});
	$('.layer3').click(function(){
		map_layer3 = $(this).attr('lid');
	});
	$('.layer4').click(function(){
		map_layer4 = $(this).attr('lid');
	});
	$('.layer5').click(function(){
		map_layer5 = $(this).attr('lid');
	});
	$('.layer6').click(function(){
		map_layer6 = $(this).attr('lid');
	});

	$('.map_to_layer').click(function(){
		$(this).addClass('highlight');
	});
	
	$('.available_map').click(function(){
		$('#select_map_name').html('Selected Map: ' + $(this).find('.map_name').text());
		active_map = $(this).find('.map_id').val();
		$(this).addClass('highlight');
	});
	
	$('.save_map_layers').click(function(){
		submit_map_data(map_layer1,map_layer2,map_layer3,map_layer4,map_layer5,map_layer6,active_map);
	});
	
	$('.placement_available_map').click(function(){
		window.location = '/editor/spawn/' + $(this).find('.placement_map_id').val();
	});
	
	$('.sprite_tile').click(function(){
	       var parent_form = $(this).parent();
		$(this).css('border','1px solid black');
		$('<input />', {
			type: 'hidden',
			name: 'sprite_id',
			value: $(this).attr('sprite_id')
		}).appendTo(parent_form);
	});
});

function save_layer(layer,name){
	var lid = layer.slice(-1);
	var tid;
	var tiles = [];
	$(layer).find('.tile_spot').each(function(index){
		tid = $(this).attr('tid');
		if(typeof(tid) == 'undefined'){
			tid = MapInfo.Layer[lid].blank_tile_id;
		}
		tiles.push(tid);
	});
	
	var o = {
		'name': name,
		'lid': lid,
		'tiles': tiles
	};
	
	$.ajax({
		url: '/editor/layer/save',
		data: JSON.stringify(o),
		type: 'POST',
		dataType: 'json',
		success: function(data){
			if(typeof data !== 'undefined' && data !== null){
				if(data.error){
					alert(data.message);
				} else {
					//function to display friendly 'it worked!';
					window.location.reload(true);
				}
			} else {
				// oh no!
			}
		}
	});
}

function submit_map_data(map_layer1,map_layer2,map_layer3,map_layer4,map_layer5,map_layer6,active_map){
	var form;
	form = $('<form />', {
		action: '/editor/map/save',
		method: 'POST',
		style: 'display: none;'
	});
	$('<input />', {
		type: 'hidden',
		name: 'layer1',
		value: map_layer1
	}).appendTo(form);
	$('<input />', {
		type: 'hidden',
		name: 'layer2',
		value: map_layer2
	}).appendTo(form);
	$('<input />', {
		type: 'hidden',
		name: 'layer3',
		value: map_layer3
	}).appendTo(form);
	$('<input />', {
		type: 'hidden',
		name: 'layer4',
		value: map_layer4
	}).appendTo(form);
	$('<input />', {
		type: 'hidden',
		name: 'layer5',
		value: map_layer5
	}).appendTo(form);
	$('<input />', {
		type: 'hidden',
		name: 'layer6',
		value: map_layer6
	}).appendTo(form);
	$('<input />', {
		type: 'hidden',
		name: 'map',
		value: active_map
	}).appendTo(form);
	form.appendTo('body').submit();

}