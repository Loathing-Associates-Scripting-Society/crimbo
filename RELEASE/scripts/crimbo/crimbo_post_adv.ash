void main()
{
	//need to track how many times either of those locations was visited today
	if($locations[site alpha dormitory, site alpha greenhouse, site alpha quarry, site alpha primary lab] contains my_location())
	{
		set_property("_crimbo21_adv", 1+get_property("_crimbo21_adv").to_int());
	}
	string enemy = get_property("lastEncounter");
	if(enemy.contains_text("ton grey goo"))
	{
		string[int] split_enemy = split_string(enemy, "-");
		int tons = split_enemy[0].to_int();
		set_property("crimbo21_enemy_tons", tons);
	}

	if(have_effect($effect[Beaten Up]) > 0)
	{
		abort("We got beaten up! This should not have happened");
	}
}
