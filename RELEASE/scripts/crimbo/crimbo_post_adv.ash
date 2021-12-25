void main()
{
	//need to track how many times either of those locations was visited today
	if($locations[site alpha dormitory, site alpha greenhouse, site alpha quarry, site alpha primary lab] contains my_location())
	{
		set_property("_crimbo21_adv", 1+get_property("_crimbo21_adv").to_int());
	}

	if(have_effect($effect[Beaten Up]) > 0)
	{
		abort("We got beaten up! This should not have happened");
	}
}
