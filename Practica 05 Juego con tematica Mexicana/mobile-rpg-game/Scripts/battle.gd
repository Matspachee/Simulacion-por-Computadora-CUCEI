extends Node2D

# Variables de UI y nodos de animación y sprites
@onready var vida: Label = $Enemy/Vida
@onready var mensaje: Label = $UI/Mensaje
@onready var animation_player: AnimationPlayer = $Enemy/AnimationPlayer
@onready var timer: Timer = $UI/Timer
@onready var inventario: Control = $UI/Inventario
@onready var botones: Control = $UI/Botones

# Botones del inventario
@onready var volver: Button = $UI/Inventario/Volver
@onready var usar: Button = $UI/Inventario/Usar
@onready var espiritu_button: Button = $UI/Inventario/EspirituButton
@onready var vela_button: Button = $UI/Inventario/VelaButton
@onready var pan_button: Button = $UI/Inventario/PanButton

# Animaciones de objetos
@onready var vela_animation: AnimationPlayer = $UI/Inventario/VelaButton/Vela/VelaAnimation
@onready var pan_animation: AnimationPlayer = $UI/Inventario/PanButton/Pan/PanAnimation
@onready var espiritu_animation: AnimationPlayer = $UI/Inventario/EspirituButton/Espiritu/EspirituAnimation

# Sprites de enemigos
@onready var enemy_sprite: Sprite2D = $Enemy/Sprite2D
@onready var fantasma: Sprite2D = $Enemy/Fantasma
@onready var calavera: Sprite2D = $Enemy/Calavera
@onready var calavera_animation: AnimationPlayer = $Enemy/Calavera/CalaveraAnimation

# Variables del juego
var enemy_life = 20
var hit = 0
var player_life = 20
var player_power = 2
var selected_item = ""
var defeated = false
var enemy_type = "fantasma"  # Tipos posibles: "fantasma", "calavera"

# Al iniciar la escena
func _ready() -> void:
	animation_player.play("Idle")  # Iniciar animación de espera
	# Conectar señales de botones y temporizador
	timer.timeout.connect(_on_timer_timeout)
	volver.pressed.connect(_on_volver_pressed)
	espiritu_button.pressed.connect(_on_espiritu_button_pressed)
	vela_button.pressed.connect(_on_vela_button_pressed)
	pan_button.pressed.connect(_on_pan_button_pressed)
	usar.pressed.connect(_on_usar_pressed)

# Temporizador: cambia de enemigo si fue derrotado
func _on_timer_timeout() -> void:
	if defeated:
		# Cambio al siguiente enemigo si se derrotó al anterior
		if enemy_type == "fantasma":
			enemy_type = "calavera"
			enemy_life = 35
			calavera.visible = true
			fantasma.visible = false
			mensaje.text = "¡Una Calavera apareció!"
		else:
			# (Se puede expandir para más enemigos)
			mensaje.text = "¡El enemigo revive!"
			enemy_life = 35

		vida.text = str(enemy_life)
		defeated = false
		animation_player.play("Idle")
		calavera_animation.play("Calavera")
	else:
		# Mostrar estado del jugador si no hay acción
		if selected_item == "":
			mensaje.text = "\nHP: " + str(player_life) + "\nPODER: " + str(player_power)
			animation_player.play("Idle")

# Ataque del jugador
func _on_attack_pressed() -> void:
	if defeated:
		return

	hit = randi_range(1, 5)  # Probabilidad de acertar

	if hit > 0 and hit < 5:
		# Golpe exitoso
		enemy_life -= player_power
		vida.text = str(enemy_life)
		mensaje.text = "\n¡Hit!\nEl enemigo pierde " + str(player_power) + " de vida..."
		animation_player.play("Hit")
	else:
		# Fallo, recibe daño del enemigo
		var enemy_damage = 4 if enemy_type == "calavera" else 1
		player_life -= enemy_damage
		mensaje.text = "\n¡Fallaste!\nPierdes " + str(enemy_damage) + " de vida..."
		animation_player.play("Push")
		timer.start(1.0)

	# Revisar si el enemigo fue derrotado
	if enemy_life <= 0:
		mensaje.text = "¡Derrotado!"
		if enemy_type == "fantasma":
			fantasma.visible = false
		elif enemy_type == "calavera":
			calavera.visible = false
		defeated = true
		timer.start(3.0)

# Acción de bloquear: no se recibe daño
func _on_bloquear_pressed() -> void:
	if defeated:
		return
	animation_player.play("Push")
	mensaje.text = "\n¡Bloqueo!\nNo pierdes vida..."
	timer.start(1.0)

# Abre o cierra el inventario
func _on_objetos_pressed() -> void:
	if defeated:
		return

	# Reproducir animaciones de los objetos
	vela_animation.play("Vela")
	pan_animation.play("Pan")
	espiritu_animation.play("new_animation")

	if botones.visible:
		# Abrir inventario
		botones.visible = false
		inventario.visible = true
		if selected_item == "":
			mensaje.text = "\nInventario abierto"
	else:
		# Cerrar inventario
		inventario.visible = false
		botones.visible = true
		if selected_item == "":
			mensaje.text = "\nVolviste al combate"
	timer.start(2.0)

# Cierra inventario sin usar objeto
func _on_volver_pressed() -> void:
	inventario.visible = false
	botones.visible = true
	mensaje.text = "\nVolviste al combate"
	selected_item = ""
	timer.start(2.0)

# Selección de cada objeto del inventario
func _on_espiritu_button_pressed() -> void:
	selected_item = "espiritu"
	mensaje.text = "\nEspíritu:\nAumenta el poder en 1"
	timer.start(5.0)

func _on_vela_button_pressed() -> void:
	selected_item = "vela"
	mensaje.text = "\nVela:\nInflige 3 de daño al enemigo."
	timer.start(5.0)

func _on_pan_button_pressed() -> void:
	selected_item = "pan"
	mensaje.text = "\nPan:\nRegenera 3 de vida."
	timer.start(5.0)

# Usa el objeto seleccionado
func _on_usar_pressed() -> void:
	if defeated:
		return

	match selected_item:
		"espiritu":
			player_power += 1
			mensaje.text = "\nHas usado el Espíritu.\n¡Poder ha aumentado en 1!"
		"vela":
			enemy_life -= 3
			if enemy_life < 0:
				enemy_life = 0
			vida.text = str(enemy_life)
			mensaje.text = "\nHas usado la Vela.\n¡Realizas 3 de daño!"
			animation_player.play("Hit")
		"pan":
			player_life += 3
			mensaje.text = "\nHas comido el Pan.\n¡Recuperaste 3 de vida!"
		_:
			mensaje.text = "\nNo has seleccionado ningún objeto."
			return

	# Verificar si el enemigo murió tras usar objeto
	if enemy_life <= 0:
		mensaje.text = "¡Derrotado!"
		if enemy_type == "fantasma":
			fantasma.visible = false
		elif enemy_type == "calavera":
			calavera.visible = false
		defeated = true
		timer.start(3.0)
	else:
		# Volver al combate
		selected_item = ""
		inventario.visible = false
		botones.visible = true
		timer.start(2.0)
