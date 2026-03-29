# maintains combat UI
extends Control

@onready var money_label: Label = $%MoneyLabel
@onready var health_label: Label = $%HealthLabel

@onready var energy_count: Label = $Energy/EnergyCount
@onready var energy: TextureButton = $Energy
@onready var draw_count: Label = $DrawPile/DrawCount
@onready var discard_count: Label = $DiscardPile/DiscardCount
@onready var exhaust_count: Label = $ExhaustPile/ExhaustCount

@onready var deck_button: TextureButton = $DeckButton
@onready var draw_pile_button: TextureButton = $DrawPile
@onready var discard_pile_button: TextureButton = $DiscardPile
@onready var exhaust_pile_button: TextureButton = $ExhaustPile

@onready var card_selection_overlay = $%CardSelectionOverlay

@onready var combat_animation_player: AnimationPlayer = $CombatAnimation
@onready var enemy_container = $EnemyContainer

@onready var player = $Player
@onready var hand = $Hand
@onready var chest = $Chest
@onready var shop = $Shop

@onready var background_button: TextureButton = %BackgroundButton

@onready var end_turn_button: Button = $EndTurnButton
var end_turn_object: CombatEndTurn = null

# 镜头控制
var camera_offset: Vector2 = Vector2.ZERO
var camera_zoom: float = 1.0
var is_dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
const MIN_ZOOM: float = 0.5
const MAX_ZOOM: float = 2.0
const ZOOM_SPEED: float = 0.1

# 移动端双指缩放
var last_pinch_distance: float = 0.0
var is_pinching: bool = false

func _ready():
	Signals.player_money_changed.connect(_on_player_money_changed)
	Signals.player_health_changed.connect(_on_player_health_changed)
	
	Signals.enemy_killed.connect(_on_enemy_killed)
	Signals.enemy_death_animation_finished.connect(_on_enemy_death_animation_finished)
	
	Signals.combat_started.connect(_on_combat_started)
	Signals.combat_started.connect(_on_combat_started_camera)
	Signals.combat_ended.connect(_on_combat_ended)
	Signals.combat_ended.connect(_on_combat_ended_camera)
	
	Signals.player_turn_started.connect(_on_player_turn_started)
	Signals.player_turn_ended.connect(_on_player_turn_ended)
	Signals.enemy_turn_ended.connect(_on_enemy_turn_ended)
	Signals.enemy_turn_started.connect(_on_enemy_turn_started)
	
	Signals.end_turn_requested.connect(_on_end_turn_requested)
	
	end_turn_button.button_up.connect(_on_end_turn_button_up)
	
	update_combat_display()
	player.update_player_display(Global.player_data)
	
	# pile buttons
	deck_button.button_up.connect(_on_deck_button_up)
	draw_pile_button.button_up.connect(_on_draw_pile_button_up)
	discard_pile_button.button_up.connect(_on_discard_pile_button_up)
	exhaust_pile_button.button_up.connect(_on_exhaust_pile_button_up)
	
	# updating pile counts when cards do things
	Signals.card_played.connect(_on_card_played)	# player is playing card
	Signals.card_drawn.connect(_on_card_drawn)
	Signals.card_deck_shuffled.connect(_on_card_deck_shuffled)
	Signals.card_discarded.connect(_on_card_discarded)
	Signals.card_exhausted.connect(_on_card_exhausted)
	
	Signals.energy_added.connect(_on_energy_added)
	Signals.card_queue_refunded.connect(_on_card_queue_refunded)
	
	Signals.run_started.connect(_on_run_started)
	Signals.run_ended.connect(_on_run_ended)
	
	Signals.map_location_selected.connect(_on_map_location_selected)

func _on_map_location_selected(location_data: LocationData):
	# determine what to do when the player visits a new location
	var location_type: int = location_data.location_type
	
	chest.visible = false
	shop.visible = false
	
	set_combat_display_visibility(false)
	
	match location_type:
		LocationData.LOCATION_TYPES.COMBAT, LocationData.LOCATION_TYPES.MINIBOSS, LocationData.LOCATION_TYPES.BOSS:
			ActionGenerator.generate_combat_start("") # emit empty event to get location's combat event
		LocationData.LOCATION_TYPES.TREASURE:
			chest.visible = true
		LocationData.LOCATION_TYPES.SHOP:
			shop.visible = true
	
	_update_background()

func update_combat_display():
	energy_count.text = str(Global.player_data.player_energy) + "/" + str(Global.player_data.player_energy_max)
	draw_count.text = str(len(Global.player_data.player_draw))
	discard_count.text = str(len(Global.player_data.player_discard))
	exhaust_count.text = str(len(Global.player_data.player_exhaust))
	_on_player_health_changed()
	_on_player_money_changed()

func _update_background() -> void:
	# set the background if possible
	var background_texture_path: String = ""
	
	var act_id: String = Global.player_data.player_act_id
	var act_data: ActData = Global.get_act_data(act_id)
	var location_data: LocationData = Global.get_player_location_data()
	
	# act background
	if act_data.act_background_texture_path != "":
		background_texture_path = act_data.act_background_texture_path
	# location background
	if location_data.location_background_texture_path != "":
		background_texture_path = location_data.location_background_texture_path
	# event background
	var location_event_object_id: String = location_data.get_location_event_object_id()
	if location_event_object_id != "":
		var event_data: EventData = Global.get_event_data(location_event_object_id)
		if event_data.event_background_texture_path != "":
			background_texture_path = event_data.event_background_texture_path
	
	if background_texture_path != "":
		background_button.texture_normal = load(background_texture_path)
	

func set_combat_display_visibility(display_visibility: bool) -> void:
	energy.visible = display_visibility
	draw_pile_button.visible = display_visibility
	discard_pile_button.visible = display_visibility
	exhaust_pile_button.visible = display_visibility
	end_turn_button.visible = display_visibility

func _on_card_played(_card_play_request: CardPlayRequest):
	update_combat_display()

func _on_card_drawn(_card_data: CardData):
	update_combat_display()

func _on_card_deck_shuffled(_is_reshuffle: bool):
	update_combat_display()

func _on_card_discarded(_card_data: CardData, _is_manual_discard: bool):
	update_combat_display()

func _on_card_exhausted(_card_data: CardData):
	update_combat_display()

func _on_energy_added(_energy_amount: int):
	update_combat_display()

func _on_card_queue_refunded():
	update_combat_display()

func _on_player_money_changed():
	money_label.text = "$%s" % Global.player_data.player_money

func _on_player_health_changed():
	health_label.text = "%s / %s" % [Global.player_data.player_health, Global.player_data.player_health_max]

### Deck Buttons

func _on_deck_button_up():
	card_selection_overlay.view_deck()
func _on_draw_pile_button_up():
	card_selection_overlay.view_draw_pile()
func _on_discard_pile_button_up():
	card_selection_overlay.view_discard()
func _on_exhaust_pile_button_up():
	card_selection_overlay.view_exhaust()

### Turn Handling

func _on_enemy_killed(enemy: Enemy):
	var generated_actions: Array[BaseAction] = ActionGenerator.create_actions(enemy, null, [], enemy.enemy_data.enemy_actions_on_death, null)
	ActionHandler.add_actions(generated_actions)
	
	
func _on_enemy_death_animation_finished(_enemy: Enemy):
	# determine if all non minion enemies killed and end combat
	var enemies: Array[Enemy] = []
	enemies.assign(get_tree().get_nodes_in_group("enemies"))
	
	var non_minion_enemies_remain: bool = true
	for enemy in enemies:
		if not enemy.enemy_data.enemy_is_minion:
			non_minion_enemies_remain = false
	
	if non_minion_enemies_remain:
		# wait for actions to finish and end combat
		if ActionHandler.actions_being_performed:
			await ActionHandler.actions_ended
		Signals.combat_ended.emit()

func _on_combat_started(event_id: String):
	var current_event: EventData = null
	if event_id == "":
		# if no event is provided, it will be derived from the location
		var current_location: LocationData = Global.get_player_location_data()
		current_event = Global.get_player_event_data()
		current_location.location_visited = true
	else:
		current_event = Global.get_event_data(event_id)
	
	enemy_container.populate_enemies(current_event)
	start_turn_animation()
	
	Global.player_data.player_energy = Global.player_data.player_energy_max
	set_combat_display_visibility(true)
	update_combat_display()
	
func _on_combat_ended():
	set_combat_display_visibility(false)
	

func perform_enemy_turn():
	# generates enemy actions and performs them in order
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	if len(enemies) == 0:
		Signals.combat_ended.emit()
		return
	
	# Enemy Turn
	for e in enemies:
		# get enemy standard attack data
		var enemy: Enemy = e	# typecast iterator
		
		
		### perform enemy start of turn statuses
		if enemy.is_alive():
			enemy.perform_status_effect_actions(StatusEffectData.STATUS_EFFECT_PROCESS_TIMES.ENEMY_START_TURN)
			if ActionHandler.actions_being_performed:
				await ActionHandler.actions_ended 
		
		### perform intent
		# NOTE: remember these go in reverse order on the stack
		if enemy.is_alive():
			# add custom actions
			var enemy_actions_data: Array[Dictionary] = []
			enemy_actions_data.assign(enemy.enemy_data.get_current_attack_custom_actions())
			
			# add attacks
			var enemy_attack: Array = enemy.enemy_data.get_current_attack_damages()
			if enemy_attack[1] > 0:
				enemy_actions_data.append(
				{
				Scripts.ACTION_ATTACK_GENERATOR: {"damage": enemy_attack[0], "number_of_attacks": enemy_attack[1], "time_delay": EnemyData.ENEMY_ATTACK_DELAY}
				}
				)
			
			# add block
			var enemy_block: int = enemy.enemy_data.get_current_attack_block()
			if enemy_block > 0:
				enemy_actions_data.append(
					{
					Scripts.ACTION_BLOCK: {
						"block": enemy_block,
						"target_override": BaseAction.TARGET_OVERRIDES.PARENT,
						"time_delay": 0.0,
						}
					}
			)
			
			# add reset block action
			enemy_actions_data.append(
			{
			Scripts.ACTION_RESET_BLOCK:  {
				"target_override": BaseAction.TARGET_OVERRIDES.PARENT,
				"time_delay": 0.0
				}
			}
			)
			
			# perform them and wait
			var enemy_attack_actions: Array = ActionGenerator.create_actions(enemy, null, [player], enemy_actions_data, null)
			ActionHandler.add_actions(enemy_attack_actions)
			if ActionHandler.actions_being_performed:
				await ActionHandler.actions_ended
		
		### Perform enemy end of turn statuses
		if enemy.is_alive():
			enemy.perform_status_effect_actions(StatusEffectData.STATUS_EFFECT_PROCESS_TIMES.ENEMY_END_TURN)
			if ActionHandler.actions_being_performed:
				await ActionHandler.actions_ended 
		
		# if player is dead stop
		if Global.player_data.player_health <= 0:
			return
	
	# all enemies dead
	enemies = get_tree().get_nodes_in_group("enemies")
	if len(enemies) == 0:
		Signals.combat_ended.emit()
		return
	
	Signals.enemy_turn_ended.emit()

	
func _on_player_turn_started():
	# prevent player from playing cards manually
	hand.hand_disabled = true
	
	# first turn actions
	if Global.get_combat_stats().turn_count == 1:
		# location initial actions
		var location_data: LocationData = Global.get_player_location_data()
		assert(location_data != null)
		if location_data != null:
			var card_play_request: CardPlayRequest = CardPlayRequest.new()	# generate fake request
			card_play_request.card_data = null
			card_play_request.selected_target = null
			
			# perform location initial actions
			var location_initial_combat_actions: Array[BaseAction] = ActionGenerator.create_actions(player, card_play_request, [], location_data.location_initial_combat_actions, null)
			ActionHandler.add_actions(location_initial_combat_actions)
		
			# wait for first turn actions
			if ActionHandler.actions_being_performed:
				await ActionHandler.actions_ended
			
			# perform event initial actions
			var event_data: EventData = Global.get_player_event_data()
			var event_initial_combat_actions: Array[BaseAction] = ActionGenerator.create_actions(player, card_play_request, [], event_data.event_initial_combat_actions, null)
			ActionHandler.add_actions(event_initial_combat_actions)
			
			# wait for first turn actions
			if ActionHandler.actions_being_performed:
				await ActionHandler.actions_ended
			
		
		# combat start card actions
		for card_data: CardData in Global.player_data.player_draw:
			var card_play_request: CardPlayRequest = CardPlayRequest.new()	# generate fake request
			card_play_request.card_data = card_data
			card_play_request.selected_target = null
			
			# perform initial actions
			var card_play_actions: Array[BaseAction] = ActionGenerator.create_actions(player, card_play_request, [], card_data.card_initial_combat_actions, null)
			ActionHandler.add_actions(card_play_actions)
	
		# wait for first turn actions
		if ActionHandler.actions_being_performed:
			await ActionHandler.actions_ended
	
	# perform pre draw actions
	player.update_incoming_damage_amount(true)
	player.generate_reset_block_action()
	player.perform_status_effect_actions(StatusEffectData.STATUS_EFFECT_PROCESS_TIMES.POST_DRAW_PLAYER_START_TURN)
	if ActionHandler.actions_being_performed:
		await ActionHandler.actions_ended
	
	# draw cards
	ActionGenerator.generate_start_of_turn_draw_actions()
	if ActionHandler.actions_being_performed:
		await ActionHandler.actions_ended
	
	# perform post draw actions
	player.perform_status_effect_actions(StatusEffectData.STATUS_EFFECT_PROCESS_TIMES.PRE_DRAW_PLAYER_START_TURN)
	
	# unlock and update hand
	hand.hand_disabled = false
	hand.update_hand_card_display()

func _on_player_turn_ended():
	# prevent player from playing cards
	hand.hand_disabled = true
	# discard non retained cards and perform card actions
	hand.perform_end_of_turn_hand_actions()
	if ActionHandler.actions_being_performed:
		await ActionHandler.actions_ended
	
	# perform all end of turn actions and await
	player.perform_status_effect_actions(StatusEffectData.STATUS_EFFECT_PROCESS_TIMES.PLAYER_END_TURN)
	if ActionHandler.actions_being_performed:
		await ActionHandler.actions_ended
	

func _on_player_start_turn_animation_finished():
	# called from animation player
	start_turn()

func _on_player_end_turn_animation_finished():
	# called from animation player
	Signals.player_turn_ended.emit()
	
	# wait for all end of turn actions to process
	if ActionHandler.actions_being_performed:
		await ActionHandler.actions_ended
	
	# start enemy turn if they're alive
	if len(get_tree().get_nodes_in_group("enemies")) > 0:
		Signals.enemy_turn_started.emit()

func _on_enemy_turn_started():
	perform_enemy_turn()
	
func _on_enemy_turn_ended():
	start_turn_animation()
	
func _on_end_turn_button_up():
	queue_end_turn(CombatEndTurn.END_TURN_QUEUE_IMMEDIACY.WAIT_FOR_ALL_CARD_PLAYS)

func _on_end_turn_requested(immediacy: int):
	queue_end_turn(immediacy)

func queue_end_turn(immediacy: int = CombatEndTurn.END_TURN_QUEUE_IMMEDIACY.WAIT_FOR_ALL_CARD_PLAYS):
	# queues up an end turn, using async objects with priority to determine how to handle it
	if end_turn_object == null:
		end_turn_object = CombatEndTurn.new(self, %Hand, immediacy)
		end_turn_object.wait()
		end_turn_button.disabled = true
	elif immediacy > end_turn_object.end_turn_queue_value:
		# higher priority end turn, replace the old with a newer one
		end_turn_object.disable()	# stop the old one working
		end_turn_object = CombatEndTurn.new(self, %Hand, immediacy)
		end_turn_object.wait()

func _reset_turn_end_queue() -> void:
	if end_turn_object != null:
		end_turn_object.disable()
		end_turn_object = null

func _on_run_started():
	visible = true
	_on_player_health_changed()
	_on_player_money_changed()
	
func _on_run_ended():
	visible = false
	_reset_turn_end_queue()

func start_combat() -> void:
	_reset_turn_end_queue()

func end_combat() -> void:
	_reset_turn_end_queue()

func end_turn():
	pass

func start_turn():
	# called from animation player
	_reset_turn_end_queue()
	Global.player_data.player_energy = Global.player_data.player_energy_max
	update_combat_display()
	Signals.player_turn_started.emit()

func end_turn_animation() -> void:
	_reset_turn_end_queue()
	combat_animation_player.play("end_turn")
	
func start_turn_animation() -> void:
	combat_animation_player.play("start_turn")

#region 镜头控制

func _input(event: InputEvent):
	# 检查是否在战斗中 - 只在有活着的敌人时处理镜头
	var in_combat = false
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is Enemy and node.is_alive():
			in_combat = true
			break
	
	# 不在战斗时不处理任何镜头输入
	if not in_combat:
		return
	
	# 鼠标滚轮缩放和拖动
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_camera_zoom(-ZOOM_SPEED)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_camera_zoom(ZOOM_SPEED)
	elif event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_camera_start_drag(event.position)
		else:
			_camera_end_drag()
	return  # 鼠标事件不继续处理
	
	# 鼠标拖动
	if event is InputEventMouseMotion and is_dragging:
		_camera_pan(event.relative)
		return
	
	# 触摸事件 - 只在战斗中进行
	if not in_combat:
		return
	
	# 移动端触摸处理
	if event is InputEventScreenTouch:
		if event.pressed:
			if not is_pinching:
				_camera_start_drag(event.position)
		else:
			if not is_pinching:
				_camera_end_drag()
			is_pinching = false
		return
	
	# 移动端双指缩放
	if event is InputEventScreenDrag:
		if event.index == 1:
			if not is_pinching:
				is_pinching = true
				last_pinch_distance = event.position.distance_to(event.global_position)
			else:
				var current_distance = event.position.distance_to(event.global_position)
				var delta = (current_distance - last_pinch_distance) * 0.01
				_camera_zoom(delta)
				last_pinch_distance = current_distance

func _camera_start_drag(mouse_pos: Vector2) -> void:
	is_dragging = true
	drag_start = mouse_pos + camera_offset

func _camera_end_drag() -> void:
	is_dragging = false

func _camera_pan(delta: Vector2) -> void:
	camera_offset = drag_start - delta
	
	# 限制范围
	var viewport_size = get_viewport_rect().size * camera_zoom
	var max_offset = viewport_size / 2
	camera_offset = camera_offset.clamp(-max_offset, max_offset)
	
	_apply_camera_transform()

func _camera_zoom(delta: float) -> void:
	camera_zoom = clampf(camera_zoom + delta, MIN_ZOOM, MAX_ZOOM)
	_apply_camera_transform()

func _apply_camera_transform() -> void:
	# 应用镜头偏移和缩放到所有战斗单位
	# 玩家和敌人用 BaseCombatant._base_screen_x 作为基准
	# 容器节点 (EnemyContainer, Hand) 用 meta "_original_position" 作为基准
	
	# 处理玩家
	if has_node("Player") and $Player.has_meta("_base_screen_x"):
		var base_x = $Player.get_meta("_base_screen_x")
		$Player.position.x = base_x + camera_offset.x
		$Player.scale = Vector2(camera_zoom, camera_zoom)
	
	# 处理敌人容器 - 每个敌人子节点单独处理
	if has_node("EnemyContainer"):
		var ec = $EnemyContainer
		ec.scale = Vector2(camera_zoom, camera_zoom)
		for child in ec.get_children():
			if child is BaseCombatant and child.has_meta("_base_screen_x"):
				var base_x = child.get_meta("_base_screen_x")
				child.position.x = base_x + camera_offset.x
				child.scale = Vector2(camera_zoom, camera_zoom)
	
	# 处理手牌容器
	if has_node("Hand"):
		var hand = $Hand
		if not hand.has_meta("_original_position"):
			hand.set_meta("_original_position", hand.position)
		var base_pos = hand.get_meta("_original_position")
		hand.position = base_pos + camera_offset
		hand.scale = Vector2(camera_zoom, camera_zoom)

func _camera_reset_transform() -> void:
	# 重置所有战斗单位的缩放和位置到原始状态
	camera_zoom = 1.0
	camera_offset = Vector2.ZERO
	
	if has_node("Player"):
		var p = $Player
		if p.has_meta("_base_screen_x"):
			p.position.x = p.get_meta("_base_screen_x")
		p.scale = Vector2.ONE
	
	if has_node("EnemyContainer"):
		var ec = $EnemyContainer
		ec.scale = Vector2.ONE
		for child in ec.get_children():
			if child is BaseCombatant and child.has_meta("_base_screen_x"):
				child.position.x = child.get_meta("_base_screen_x")
				child.scale = Vector2.ONE
	
	if has_node("Hand"):
		var hand = $Hand
		if hand.has_meta("_original_position"):
			hand.position = hand.get_meta("_original_position")
		hand.scale = Vector2.ONE

func _get_combat_nodes() -> Array[Control]:
	var nodes: Array[Control] = []
	if has_node("Player"):
		nodes.append($Player)
	if has_node("EnemyContainer"):
		nodes.append($EnemyContainer)
	if has_node("Hand"):
		nodes.append($Hand)
	return nodes

func _save_original_positions() -> void:
	var combat_nodes = _get_combat_nodes()
	for node in combat_nodes:
		if node is Control and not node.has_meta("_original_position"):
			node.set_meta("_original_position", node.position)

func _on_combat_started_camera(_event_id: String):
	# 战斗开始时保存原始位置并自动适应视角
	_save_original_positions()
	_camera_fit_all_combatants()

func _camera_fit_all_combatants() -> void:
	var player = Global.get_player()
	if player == null:
		return
	
	var min_x: float = player.position_x
	var max_x: float = player.position_x
	
	# 获取所有敌人位置
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is BaseCombatant:
			min_x = minf(min_x, enemy.position_x)
			max_x = maxf(max_x, enemy.position_x)
	
	# 计算范围
	var combat_range = max_x - min_x
	if combat_range <= 0:
		combat_range = 200
	
	# 计算缩放
	var viewport_width = get_viewport_rect().size.x
	camera_zoom = clampf(viewport_width / (combat_range + 300), MIN_ZOOM, MAX_ZOOM)
	
	# 计算居中偏移
	var center_x = (min_x + max_x) / 2
	camera_offset = Vector2(viewport_width / 2 - center_x * camera_zoom, 0)
	
	_apply_camera_transform()

func _on_combat_ended_camera():
	# 战斗结束重置所有战斗单位的变换
	is_pinching = false
	_camera_reset_transform()

# 移动战斗单位
func move_combatant(combatant: BaseCombatant, new_x: float) -> void:
	if combatant == null:
		return
	combatant.set_position_x(new_x)
	Signals.combatant_moved.emit(combatant)

# 玩家移动到指定位置
func move_player_to(x: float) -> void:
	if player == null:
		return
	move_combatant(player, x)

#endregion

#region 镜头控制
