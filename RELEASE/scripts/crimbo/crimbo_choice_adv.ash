script "crimbo_choice_adv.ash";
import <autoscend/auto_choice_adv.ash>

boolean crimbo_run_choice(int choice, string page)
{
	print("Running crimbo_choice_adv.ash");
	
	switch (choice)
	{
		case 1461: //crimbo 2021 site alpha primary lab
			int ton_now = get_property("crimbo21_enemy_tons").to_int();
			int ton_goal = get_property("crimbo21_tons_desired").to_int();
			ton_goal = max(10,ton_goal);		//hidden value can go under 10 but enemy tons can never go below 10
			if(available_choice_options() contains 5)
			{
				run_choice(5);	//Grab the Cheer Core. once per account. blocks all other options.
			}
			else if(ton_now < ton_goal)
			{
				run_choice(1);	//turn knob right. +1 ML
			}
			else if(ton_now > ton_goal)
			{
				run_choice(2);	//turn knob left. -1 ML. can not go below 10
			}
			else
			{
				run_choice(4);	//skip adv
			}
			//choice 3: Drop a grey goo ring into the slot. destroy it and gain +300 assorted goo items
			break;
		default:
			return auto_run_choice(choice, page);
			break;
	}
	
	return true;
}

void main(int choice, string page)
{
	boolean ret = false;
	try
	{
		ret = crimbo_run_choice(choice, page);
	}
	finally
	{
		if (!ret)
		{
			auto_log_error("Error running crimbo_choice_adv.ash, setting auto_interrupt=true");
			set_property("auto_interrupt", true);
		}
	}
}
