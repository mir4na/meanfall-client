extends Node

const LEAGUE_THRESHOLDS := {
	"Bronze":   0,
	"Silver":   500,
	"Gold":     1500,
	"Platinum": 3000,
	"Diamond":  6000,
}

const RANK_POINTS := {
	1: 100,
	2: 60,
	3: 30,
	4: 10,
}

func get_points_for_rank(rank: int) -> int:
	return RANK_POINTS.get(rank, 0)

func get_league(total_points: int) -> String:
	var league := "Bronze"
	for name in LEAGUE_THRESHOLDS:
		if total_points >= LEAGUE_THRESHOLDS[name]:
			league = name
	return league

func get_next_league_threshold(total_points: int) -> int:
	var thresholds := LEAGUE_THRESHOLDS.values()
	thresholds.sort()
	for t in thresholds:
		if total_points < t:
			return t
	return -1

func submit_match_result(rank: int) -> void:
	var points := get_points_for_rank(rank)
	NakamaManager.rpc_call("submit_rank", {
		"rank": rank,
		"pointsGained": points
	})
