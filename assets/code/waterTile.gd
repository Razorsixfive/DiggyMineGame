extends Resource
class_name waterTile

# ---------- Variables ----------
# Represents air level.
var luft: int = 0
# Represents water level.
var water: int = 0
# Represents water pressure.
var vandTryk: int = 0
# Flag to indicate if update is needed.
var update: bool = true
# Flag to indicate if update is needed next.
var updateNext: bool = false
