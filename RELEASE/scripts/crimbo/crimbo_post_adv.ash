void main()
{
	//need to track how many times either of those locations was visited today
	if($location[Site Alpha Dormitory] == my_location())
	{
		set_property("_crimbo21_dormitory", 1+get_property("_crimbo21_dormitory").to_int());
	}
	if($location[Site Alpha Greenhouse] == my_location())
	{
		set_property("_crimbo21_greenhouse", 1+get_property("_crimbo21_greenhouse").to_int());
	}

	if(have_effect($effect[Beaten Up]) > 0)
	{
		abort("We got beaten up! This should not have happened");
	}
}
