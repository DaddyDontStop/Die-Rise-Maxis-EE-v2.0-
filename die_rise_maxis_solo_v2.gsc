#include maps/mp/zm_highrise_sq;
#include maps/mp/zombies/_zm_sidequests;
#include maps/mp/zombies/_zm_utility;
#include maps/mp/_utility;
#include common_scripts/utility;
#include maps/mp/zm_highrise_sq_pts;
#include maps/mp/zm_highrise_sq_atd;
#include maps/mp/zombies/_zm_equip_springpad;
#include maps/mp/zombies/_zm_equipment;

main()
{
	replaceFunc( ::watchspringpaduse, ::watch_springpad_use );
	replaceFunc( ::cleanupoldspringpad, ::clean_up_old_springpad );
	replaceFunc( ::sq_atd_elevators, ::custom_sq_atd_elevators );
	replaceFunc( ::sq_atd_drg_puzzle, ::custom_sq_atd_drg_puzzle );
	replaceFunc( ::drg_puzzle_trig_think, ::custom_drg_puzzle_trig_think );
	replaceFunc( ::wait_for_all_springpads_placed, ::custom_wait_for_all_springpads_placed );
	replaceFunc( ::springpad_count_watcher, ::custom_springpad_count_watcher );
	replaceFunc( ::pts_should_player_create_trigs, ::custom_pts_should_player_create_trigs );
	replaceFunc( ::pts_putdown_trigs_create_for_spot, ::custom_pts_putdown_trigs_create_for_spot );
	replaceFunc( ::pts_putdown_trigs_remove_for_player, ::custom_pts_putdown_trigs_remove_for_player );
	replaceFunc( ::pts_putdown_trigs_remove_for_spot, ::custom_pts_putdown_trigs_remove_for_spot );
	replaceFunc( ::place_ball_think, ::custom_place_ball_think );
}

init()
{
	level.inital_spawn = true;
	thread onplayerconnect();
}

onplayerconnect()
{
	while(true)
	{
		level waittill("connecting", player);
		player thread onplayerspawned();
	}
}

onplayerspawned()
{
	level endon( "game_ended" );
	self endon( "disconnect" );
	self.initial_spawn = true;
	for(;;)
	{
		self waittill( "spawned_player" );
		if(level.inital_spawn)
		{
			level.inital_spawn = false;
			
		}
		if (self.initial_spawn)
		{
			self.initial_spawn = false;
			self thread quick_release();
			self thread ignore_buildables();
		}
	}
}

custom_pts_should_player_create_trigs( player ) 
{
	a_lion_spots = getstructarray( "pts_lion", "targetname" );
	_a467 = a_lion_spots;
	_k467 = getFirstArrayKey( _a467 );
	while ( isDefined( _k467 ) )
	{
		s_lion_spot = _a467[ _k467 ];
		if ( isDefined( s_lion_spot.springpad ) ) 
		{
			custom_pts_putdown_trigs_create_for_spot( s_lion_spot, player );
		}
		_k467 = getNextArrayKey( _a467, _k467 ); 
	}
}

custom_pts_putdown_trigs_create_for_spot( s_lion_spot, player ) 
{
	if ( isDefined( s_lion_spot.which_ball ) || isDefined( s_lion_spot.springpad_buddy ) && isDefined( s_lion_spot.springpad_buddy.which_ball ) )
	{
		return;
	}
	t_place_ball = sq_pts_create_use_trigger( s_lion_spot.origin, 48, 50, &"ZM_HIGHRISE_SQ_PUTDOWN_BALL" ); // (16,70)
	player clientclaimtrigger( t_place_ball );
	t_place_ball.owner = player;
	player thread place_ball_think( t_place_ball, s_lion_spot );
	if ( !isDefined( s_lion_spot.pts_putdown_trigs ) )
	{
		s_lion_spot.pts_putdown_trigs = [];
	}
	s_lion_spot.pts_putdown_trigs[ player.characterindex ] = t_place_ball;
}

custom_place_ball_think( t_place_ball, s_lion_spot ) 
{
	t_place_ball endon( "delete" );
	t_place_ball waittill( "trigger" );
	self.zm_sq_has_ball = undefined;
	s_lion_spot.which_ball = self.which_ball;
	self notify( "zm_sq_ball_used" );
	s_lion_spot.zm_pts_animating = 1;
	s_lion_spot.springpad_buddy.zm_pts_animating = 1;
	flag_set( "pts_2_generator_" + level.current_generator + "_started" );
	s_lion_spot.which_generator = level.current_generator;
	level.current_generator++;
	s_lion_spot.springpad thread pts_springpad_fling( s_lion_spot.script_noteworthy, s_lion_spot.springpad_buddy.springpad );
}

custom_pts_putdown_trigs_remove_for_player( player ) 
{
}

custom_pts_putdown_trigs_remove_for_spot( s_lion_spot ) 
{
}

custom_springpad_count_watcher( is_generator ) //Report springpad counts 
{
	level endon( "sq_pts_springad_count4" );
	n_count = 0; 
	while ( n_count < 5 )	
	{
		n_count++;
		level notify( "sq_pts_springad_count" + n_count );
		wait 5;
	}
}

custom_wait_for_all_springpads_placed( str_type, str_flag ) //Springpad count skip 
{
	//str_type is basically useless, but has to be kept as other functions will call with an str_type
	while ( !flag( str_flag ) )	
	{
		flag_set( str_flag );
		wait 1;
	}
}

ignore_buildables() 
{
	level endon("end_game");
	self endon("disconnect");
	equipment = getFirstArrayKey(level.zombie_include_equipment);
	while (isDefined(equipment))
	{
		maps/mp/zombies/_zm_equipment::enemies_ignore_equipment(equipment);
		equipment = getNextArrayKey(level.zombie_include_equipment, equipment);
	}
}

quick_release()
{
	i = 0; 
	while( i < 6 ) // variable 
	{
		self waittill( "equipment_placed" );
		self equipment_take( "equip_springpad_zm" ); 
		i++;
	}
}

clean_up_old_springpad()
{
}

watch_springpad_use()
{
	self notify( "watchSpringPadUse" );
	self endon( "death" );
	self endon( "disconnect" );
	for ( ;; )
	{
		self waittill( "equipment_placed", weapon, weapname );
		if ( weapname == level.springpad_name )
		{
			self.buildablespringpad = weapon;
			self thread startspringpaddeploy( weapon );
		}
	}
}

//Elevator Stand step
custom_sq_atd_elevators(){
	a_elevators = array( "elevator_bldg1b_trigger", "elevator_bldg1d_trigger", "elevator_bldg3b_trigger", "elevator_bldg3c_trigger" );
	a_elevator_flags = array( "sq_atd_elevator0", "sq_atd_elevator1", "sq_atd_elevator2", "sq_atd_elevator3" );
	i = 0;
	while ( i < a_elevators.size )	{
		trig_elevator = getent( a_elevators[ i ], "targetname" );
		trig_elevator thread sq_atd_watch_elevator( a_elevator_flags[ i ] );
		i++;
	}
	//While no elevator, wait until any and break
	while ( !flag( "sq_atd_elevator0" ) && !flag( "sq_atd_elevator1" ) && !flag( "sq_atd_elevator2" ) && !flag( "sq_atd_elevator3" ) ){
		flag_wait_any_array( a_elevator_flags );
		wait 0.5;
	}	
	a_dragon_icons = getentarray( "elevator_dragon_icon", "targetname" );
	_a105 = a_dragon_icons;
	_k105 = getFirstArrayKey( _a105 );
	while ( isDefined( _k105 ) )	{
		m_icon = _a105[ _k105 ];
		v_off_pos = m_icon.m_lit_icon.origin;
		m_icon.m_lit_icon unlink();
		m_icon unlink();
		m_icon.m_lit_icon.origin = m_icon.origin;
		m_icon.origin = v_off_pos;
		m_icon.m_lit_icon linkto( m_icon.m_elevator );
		m_icon linkto( m_icon.m_elevator );
		m_icon playsound( "zmb_sq_symbol_light" );
		_k105 = getNextArrayKey( _a105, _k105 );
	}
	flag_set( "sq_atd_elevator_activated" );
	vo_richtofen_atd_elevators();
	level thread vo_maxis_atd_elevators();
}

//Dragon Puzzle step
custom_sq_atd_drg_puzzle(){
//No reset, requires as many dragons as players in the match
	level.sq_atd_cur_drg = (4 - getPlayers().size);
	a_puzzle_trigs = getentarray( "trig_atd_drg_puzzle", "targetname" );
	a_puzzle_trigs = array_randomize( a_puzzle_trigs );
	i = (0);
	while ( i < a_puzzle_trigs.size )	{
		a_puzzle_trigs[ i ] thread drg_puzzle_trig_think( i );
		i++;
	}
	while ( level.sq_atd_cur_drg < 4 )	{
		wait 1;
	}
	flag_set( "sq_atd_drg_puzzle_complete" );
	level thread vo_maxis_atd_order_complete();

}

custom_drg_puzzle_trig_think( n_order_id ){
	self.drg_active = 0;
	m_unlit = getent( self.target, "targetname" );
	m_lit = m_unlit.lit_icon;
	v_top = m_unlit.origin;
	v_hidden = m_lit.origin;
	while ( !flag( "sq_atd_drg_puzzle_complete" ) )	{
		while ( self.drg_active )		{
			level waittill( "sq_atd_drg_puzzle_complete" );
		}
		self waittill( "trigger", e_who );
		if ( level.sq_atd_cur_drg == n_order_id )		{
			m_lit.origin = v_top;
			m_unlit.origin = v_hidden;
			m_lit playsound( "zmb_sq_symbol_light" );
			self.drg_active = 1;
			level thread vo_richtofen_atd_order( level.sq_atd_cur_drg );
			level.sq_atd_cur_drg++;
			self thread drg_puzzle_trig_watch_fade( m_lit, m_unlit, v_top, v_hidden );
		}
		while ( e_who istouching( self ) )		{
			wait 0.5;
		}
	}
}