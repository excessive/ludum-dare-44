package ai;

class GOAP {
	var plan: ActionPlanner;

	public function new() {
		plan = new ActionPlanner();

		// not aware of any enemies, wander around.
		plan.set_pre ("go_home", "aggro", false);
		plan.set_pre ("go_home", "healthy", false);
		plan.set_post("go_home", "at_nest", false);
		plan.set_post("go_home", "at_nest", true);

		// we're hurt and the enemy isn't nearby, try to recover
		plan.set_pre ("recover", "enemy_nearby", false);
		plan.set_pre ("recover", "healthy", false);
		plan.set_pre ("recover", "at_nest", true);
		plan.set_post("recover", "healthy", true);

		// we're hurt and the enemy is close, get out of here
		plan.set_pre ("flee", "enemy_nearby", true);
		plan.set_pre ("flee", "healthy", false);
		plan.set_post("flee", "enemy_nearby", false);
		plan.set_post("flee", "at_nest", true);

		// we're healthy, but player has pissed us off
		plan.set_pre ("search", "aggro", true);
		plan.set_pre ("search", "healthy", true);
		plan.set_post("search", "enemy_nearby", true);

		// enemy is nearby, but we don't know where
		plan.set_pre ("investigate", "enemy_visible", false);
		plan.set_pre ("investigate", "enemy_nearby", true);
		plan.set_post("investigate", "enemy_visible", true);

		plan.set_pre ("guard", "enemy_visible", true);
		plan.set_pre ("guard", "enemy_nearby", false);
		plan.set_post("guard", "aggro", true);

		// the enemy is here, take them out
		plan.set_pre ("attack", "enemy_visible", true);
		plan.set_pre ("attack", "enemy_nearby", true);
		plan.set_pre ("attack", "aggro", true);
		plan.set_post("attack", "enemy_alive", false);
		plan.set_post("attack", "aggro", false);
		// trace(plan.describe());

		var start = new WorldState();
		plan.set_flag(start, "at_nest", false);
		plan.set_flag(start, "enemy_visible", true);
		plan.set_flag(start, "enemy_nearby", true);
		plan.set_flag(start, "aggro", true);
		plan.set_flag(start, "healthy", false);
		plan.set_flag(start, "enemy_alive", true);

		var goal = new WorldState();
		plan.set_flag(goal, "healthy", true);
		plan.set_flag(goal, "aggro", false);
		// plan.set_flag(goal, "alive", true);

		trace('\n'
			+ 'current state: ${plan.describe_state(start)}\n'
			+ 'desired state: ${plan.describe_state(goal)}'
		);
		var plan = Astar.plan(plan, start, goal);
		for (i in 0...plan.actions.length) {
			trace(i, plan.actions[i]);
		}
	}
}
