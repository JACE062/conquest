extends RefCounted

# Web localStorage commits synchronously, before the reminder or AI handoff.
const KEY = "conquest.end-turn.v1"

static func write(data: Dictionary) -> bool:
	var bytes = var_to_bytes(data).compress(FileAccess.COMPRESSION_GZIP)
	var encoded = Marshalls.raw_to_base64(bytes)
	# Use a string acknowledgement across the web bridge and verify the write.
	var script = """(() => {
		try {
			const key = '%s', value = '%s';
			localStorage.setItem(key, value);
			return localStorage.getItem(key) === value ? 'saved' : '';
		} catch (_) { return ''; }
	})()"""
	return JavaScriptBridge.eval(script % [KEY,encoded]) == "saved"

static func read() -> Dictionary:
	if not OS.has_feature("web"):
		return {}
	var encoded = JavaScriptBridge.eval("try { localStorage.getItem('%s') } catch (_) { null }" % KEY)
	if not encoded is String or encoded.is_empty():
		return {}
	var bytes = Marshalls.base64_to_raw(encoded).decompress_dynamic(64 * 1024 * 1024,FileAccess.COMPRESSION_GZIP)
	if bytes.is_empty():
		return {}
	var data = bytes_to_var(bytes)
	if data is Dictionary and data.has_all(["island","houses","difficulty","cells","round","wait","graph","undo","selected","source","mode","cursor","zoom","center"]) and data.island in preload("res://game/island.gd").MAPS:
		return data
	return {}

static func clear():
	if OS.has_feature("web"):
		JavaScriptBridge.eval("try { localStorage.removeItem('%s') } catch (_) {}" % KEY)

# Snapshots share most tiles. Store only the tiles each undo would change.
static func pack_history(history: Array, cells: Dictionary) -> Array:
	var undo = []
	var newer = cells
	for i in range(history.size()-1,-1,-1):
		var older = history[i][0]
		var changes = {}
		for p in older:
			if older[p] != newer[p]:
				changes[p] = older[p]
		undo.append([changes,history[i][1]])
		newer = older
	return undo

static func unpack_history(undo: Array, cells: Dictionary) -> Array:
	var history = []
	var newer = cells
	for entry in undo:
		var older = newer.duplicate(true)
		older.merge(entry[0],true)
		history.append([older,entry[1]])
		newer = older
	history.reverse()
	return history
