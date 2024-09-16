extends PanelContainer

@onready var air_bar = $GridContainer/airBar
@onready var hp_bar = $GridContainer/hpBar
@onready var coin_label = $GridContainer/coin

func setMaxAir(air: int):
	air_bar.max_value = air
func setAir(air: int):
	air_bar.value = air
	
func setMaxHp(Hp: int):
	hp_bar.max_value = Hp
func setHp(Hp: int):
	hp_bar.value = Hp

func setCoin(coin: int):
	coin_label.text = "$:" + str(coin)
