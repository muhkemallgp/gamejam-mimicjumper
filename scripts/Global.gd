extends Node

# Global state — persist across scene reloads.

# ============= Level progression =============
var current_level: int = 1
const MAX_LEVEL: int = 5

# Bonus level tracking
var bonus_return_level: int = 0
var bonus_visited_this_run: bool = false

# ============= D29 secret mechanic =============
var secret_fall_count: int = 0
var secret_unlocked: bool = false

# ============= Coin tracking =============
var total_coins: int = 0                  # Cumulative across run
var level_coins_collected: int = 0        # Resets per regular level
var level_coins_max: int = 0              # Set per level at _ready

# ============= Intermission state =============
var intermission_level_num: int = 1
var intermission_coins_collected: int = 0
var intermission_coins_max: int = 0
var intermission_came_from_bonus: bool = false

# ============= Player stats =============
var lives: int = 5
const MAX_LIVES: int = 5
var attempt_count: int = 1

# ============= Thresholds =============
var level_thresholds: Dictionary = {
	1: 8,
	2: 14,
	3: 15,
	4: 18,
	5: 20,
}

# ============= Profile (persistent across runs) =============
var wallet: int = 0
var unlocked_skins: Array = ["mask_dude"]
var selected_skin: String = "mask_dude"

const SKINS: Dictionary = {
	"mask_dude":   {"name": "Mask Dude",   "price": 0,   "color": Color(1, 1, 1, 1)},
	"pink_man":    {"name": "Pink Man",    "price": 30,  "color": Color(1, 0.7, 0.85, 1)},
	"ninja_frog":  {"name": "Ninja Frog",  "price": 60,  "color": Color(0.6, 1, 0.6, 1)},
	"virtual_guy": {"name": "Virtual Guy", "price": 100, "color": Color(0.7, 0.85, 1, 1)},
}
const SKIN_ORDER: Array = ["mask_dude", "pink_man", "ninja_frog", "virtual_guy"]

# ============= Lifecycle =============

func _ready() -> void:
	load_profile()


func reset_for_new_game() -> void:
	current_level = 1
	bonus_return_level = 0
	bonus_visited_this_run = false
	secret_fall_count = 0
	secret_unlocked = false
	total_coins = 0
	level_coins_collected = 0
	level_coins_max = 0
	lives = MAX_LIVES
	attempt_count = 1
	pending_resume = false
	resume_position = Vector2.ZERO
	clear_run_save()


func reset_secret_state() -> void:
	secret_fall_count = 0
	secret_unlocked = false


func reset_level_coins() -> void:
	level_coins_collected = 0


func lose_life() -> void:
	lives -= 1
	attempt_count += 1


func gain_life() -> bool:
	if lives >= MAX_LIVES:
		return false
	lives += 1
	return true


func trigger_secret_fall() -> void:
	secret_fall_count += 1
	lives += 1
	print("💀 Secret fall #", secret_fall_count, " in level ", current_level)
	if secret_fall_count >= 3:
		secret_unlocked = true
		print("✨ SECRET UNLOCKED in level ", current_level)


func is_game_over() -> bool:
	return lives <= 0


func meets_threshold() -> bool:
	var threshold: int = level_thresholds.get(intermission_level_num, 0)
	return intermission_coins_collected >= threshold


func get_current_threshold() -> int:
	return level_thresholds.get(intermission_level_num, 0)


# ============= Scene routing =============

func prepare_intermission(from_bonus: bool = false) -> void:
	intermission_level_num = current_level
	intermission_coins_collected = level_coins_collected
	intermission_coins_max = level_coins_max
	intermission_came_from_bonus = from_bonus


func advance_level_after_intermission() -> String:
	# Bank coins to wallet for cleared levels.
	wallet += level_coins_collected
	# Stale resume position from previous level must not carry over.
	pending_resume = false
	resume_position = Vector2.ZERO
	reset_secret_state()
	reset_level_coins()
	if intermission_came_from_bonus:
		current_level = bonus_return_level
	else:
		current_level += 1
	if current_level > MAX_LEVEL:
		clear_run_save()
		save_profile()
		return "res://scenes/EpilogScene.tscn"
	save_run()
	return "res://scenes/Level%d.tscn" % current_level


func retry_current_level() -> String:
	# Called by Intermission FAIL → Retry. Refund coins from this attempt
	# so player doesn't double-count when they replay the same level.
	total_coins -= level_coins_collected
	if total_coins < 0:
		total_coins = 0
	reset_secret_state()
	reset_level_coins()
	pending_resume = false
	resume_position = Vector2.ZERO
	return "res://scenes/Level%d.tscn" % current_level


func retry_after_gameover() -> String:
	# Called by GameOverScreen → Retry Level. Resume at current level.
	# Refund coins from THIS unfinished level so replaying it isn't abusable
	# (player can't farm coins by dying repeatedly on the same level).
	# Coins from PREVIOUS levels (already banked at intermission pass) stay safe.
	total_coins -= level_coins_collected
	if total_coins < 0:
		total_coins = 0
	lives = MAX_LIVES
	attempt_count += 1
	reset_secret_state()
	reset_level_coins()
	pending_resume = false
	resume_position = Vector2.ZERO
	return "res://scenes/Level%d.tscn" % current_level


# ============= Resume from Death =============
const RESUME_COST: int = 10
var pending_resume: bool = false
var resume_position: Vector2 = Vector2.ZERO


func can_resume() -> bool:
	return total_coins >= RESUME_COST


func try_resume() -> String:
	# Spend coins, give 1 life, resume from last death position.
	# level_coins_collected is preserved (player continues attempt, doesn't restart).
	if not can_resume():
		return ""
	total_coins -= RESUME_COST
	lives = 2  # 1 life + 1 buffer (so player isn't instantly dead from same hazard)
	pending_resume = true
	attempt_count += 1
	return "res://scenes/Level%d.tscn" % current_level


func consume_resume_position() -> Vector2:
	# Called by Level._ready to fetch + clear the resume position.
	var pos: Vector2 = resume_position
	pending_resume = false
	resume_position = Vector2.ZERO
	return pos


func enter_bonus_level() -> String:
	bonus_visited_this_run = true
	bonus_return_level = current_level + 1
	return "res://scenes/BonusLevel.tscn"


# ============= Shop =============

func can_afford(skin_id: String) -> bool:
	return wallet >= int(SKINS.get(skin_id, {}).get("price", 999999))


func is_unlocked(skin_id: String) -> bool:
	return skin_id in unlocked_skins


func buy_skin(skin_id: String) -> bool:
	if is_unlocked(skin_id):
		return false
	if not can_afford(skin_id):
		return false
	wallet -= int(SKINS[skin_id]["price"])
	unlocked_skins.append(skin_id)
	save_profile()
	return true


func equip_skin(skin_id: String) -> void:
	if is_unlocked(skin_id):
		selected_skin = skin_id
		save_profile()


# ============= Save / Continue =============

const SAVE_PATH: String = "user://mimic_save.json"


func _read_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return {}
	var raw: String = f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _write_save(data: Dictionary) -> void:
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()


func save_run() -> void:
	var data: Dictionary = _read_save()
	data["run"] = {
		"current_level": current_level,
		"total_coins": total_coins,
		"lives": lives,
		"bonus_visited_this_run": bonus_visited_this_run,
	}
	data["profile"] = _profile_dict()
	_write_save(data)


func save_profile() -> void:
	var data: Dictionary = _read_save()
	data["profile"] = _profile_dict()
	_write_save(data)


func _profile_dict() -> Dictionary:
	return {
		"wallet": wallet,
		"unlocked_skins": unlocked_skins,
		"selected_skin": selected_skin,
	}


func load_profile() -> void:
	var data: Dictionary = _read_save()
	var p = data.get("profile", {})
	if typeof(p) != TYPE_DICTIONARY:
		return
	wallet = int(p.get("wallet", 0))
	var skins = p.get("unlocked_skins", ["mask_dude"])
	if typeof(skins) == TYPE_ARRAY:
		unlocked_skins = skins
	if "mask_dude" not in unlocked_skins:
		unlocked_skins.append("mask_dude")
	selected_skin = String(p.get("selected_skin", "mask_dude"))
	if not is_unlocked(selected_skin):
		selected_skin = "mask_dude"


func has_save() -> bool:
	var data: Dictionary = _read_save()
	return data.has("run")


func load_progress() -> bool:
	var data: Dictionary = _read_save()
	if not data.has("run"):
		return false
	var run = data["run"]
	current_level = int(run.get("current_level", 1))
	total_coins = int(run.get("total_coins", 0))
	lives = int(run.get("lives", MAX_LIVES))
	bonus_visited_this_run = bool(run.get("bonus_visited_this_run", false))
	bonus_return_level = 0
	secret_fall_count = 0
	secret_unlocked = false
	level_coins_collected = 0
	attempt_count = 1
	# Profile already loaded at startup.
	return true


func clear_run_save() -> void:
	# Wipe run section but keep profile (wallet/skins persist).
	var data: Dictionary = _read_save()
	if data.has("run"):
		data.erase("run")
	data["profile"] = _profile_dict()
	_write_save(data)


func clear_save() -> void:
	# Total wipe (legacy alias). Now redirects to clear_run_save to preserve profile.
	clear_run_save()
