$(document).ready(function(){

	Positions = {};
	var last_creature = {
		'object_type': '',
		'uuid': '',
		'background_position': '',
		'background_image': '',
		'map_id': ''
	};
	$('.game_tile').click(function(){
		var tile_id = $(this).attr('tile_id');
		Positions[tile_id] = {};
		Positions[tile_id].x = $(this).attr('x');
		Positions[tile_id].y = $(this).attr('y');
		Positions[tile_id].type = last_creature.object_type;
		Positions[tile_id].id = last_creature.uuid;
		Positions[tile_id].map_id = $('#map').attr('map_id');
		console.log($(this).attr('tile_id'));
		console.log(tile_id);
		$('#character').find("div[tile_id='" + $(this).attr('tile_id') +"']").css('background',last_creature.background_image).css('background-position',last_creature.background_position);
	});

	$('.sprite_tile').click(function(){
		last_creature.object_type = $(this).attr('object_type');
		last_creature.uuid = $(this).attr('uuid');
		last_creature.background_position = $(this).css('background-position');
		last_creature.background_image = $(this).css('background-image');
	});
	
	$('.save_spawns').click(function(){
		var d = JSON.stringify(Positions);
		var u = '/editor/spawn/save';
		$.ajax({
			url: u,
			dataType: 'json',
			data: d,
			type: 'POST',
			success: function(e){
				window.location.reload(true);
			}
		});
	});
});