extends PanelContainer

# ---------- Onready Nodes ----------
@onready var air_bar = $GridContainer/airBar
@onready var hp_bar = $GridContainer/hpBar
@onready var coin_label = $GridContainer/coin

# ---------- Air Management ----------
# Sets the maximum value for the air bar.
func setMaxAir(air: int):
	air_bar.max_value = air

# Sets the current value for the air bar.
func setAir(air: int):
	air_bar.value = air

# ---------- HP Management ----------
# Sets the maximum value for the HP bar.
func setMaxHp(Hp: int):
	hp_bar.max_value = Hp

# Sets the current value for the HP bar.
func setHp(Hp: int):
	hp_bar.value = Hp

# ---------- Coin Management ----------
# Updates the coin label with the current coin count.
func setCoin(coin: int):
	coin_label.text = "$:" + str(coin)

