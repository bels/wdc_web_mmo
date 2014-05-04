$(document).ready(function(){

//this system really only works for a single player game.  need to fixify
	tiles_x = 32;
	tiles_y = 32;
	tile_size_x = 32;
	tile_size_y = 32;
	map_offset = $('#map').offset();

	$('#map').attr('tabindex',-1).focus();
	$('#map').keydown(function(event){
		event.preventDefault();
		if(event.which == 39){
			var data = {
				'Entity': player.get_name(),
				'id': player.get_id(),
				'direction': 'right',
				'distance': '+=' + tile_size_x,
				'x': player.get_x() + 1,
				'y': player.get_y(),
				'current_map': player.get_map(),
				'current_tile': player.get_current_tile() + 1,
				'type': 'character',
				'event_id': UUID.generate()
			};
			Dispatcher.registerEvent({'event_id': data.event_id, 'action': 'move'});
			ws.send(JSON.stringify({'data': data, 'action': 'move'}));
		}
		if(event.which == 37){
			var data = {
				'Entity': player.get_name(),
				'id': player.get_id(),
				'direction': 'left',
				'distance': '-=' + tile_size_x,
				'x': player.get_x() - 1,
				'y': player.get_y(),
				'current_map': player.get_map(),
				'current_tile': player.get_current_tile() - 1,
				'type': 'character',
			    'event_id': UUID.generate()
			};
			Dispatcher.registerEvent({'event_id': data.event_id, 'action': 'move'});
			ws.send(JSON.stringify({'data': data, 'action': 'move'}));
		}
		if(event.which == 40){
			var data = {
				'Entity': player.get_name(),
				'id': player.get_id(),
				'direction': 'down',
				'distance': '+=' + tile_size_y,
				'x': player.get_x(),
				'y': player.get_y() + 1,
				'current_map': player.get_map(),
				'current_tile': player.get_current_tile() + 32,
				'type': 'character',
				'event_id': UUID.generate()
			};
			Dispatcher.registerEvent({'event_id': data.event_id, 'action': 'move'});
			ws.send(JSON.stringify({'data': data, 'action': 'move'}));
		}
		if(event.which == 38){
			var data = {
				'Entity': player.get_name(),
				'id': player.get_id(),
				'direction': 'up',
				'distance': '-=' + tile_size_y,
				'x': player.get_x(),
				'y': player.get_y() - 1,
				'current_map': player.get_map(),
				'current_tile': player.get_current_tile() - 32,
				'type': 'character',
				'event_id': UUID.generate()
			};
			Dispatcher.registerEvent({'event_id': data.event_id, 'action': 'move'});
			ws.send(JSON.stringify({'data': data, 'action': 'move'}));
		}
	});
	
	collision_data = new Object();
	$('.collision_tile').each(function(){
		collision_data[$(this).text()] = 1;
	});
});