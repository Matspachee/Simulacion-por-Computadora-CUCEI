extends Node

var score = 0
@onready var puntuacion: Label = $"../Texto/Puntuacion"


func add_point():
	score += 1
	puntuacion.text = "Buen trabajo \nObtuviste\n" + str(score) + "\nMonedas !!! "
	print(score)
