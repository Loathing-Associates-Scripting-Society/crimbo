script "crimbo_choice_adv.ash";
import <autoscend/auto_choice_adv.ash>

boolean crimbo_run_choice(int choice, string page)
{
	print("Running crimbo_choice_adv.ash");
	
	switch (choice)
	{
		case 1461: //crimbo 2021 site alpha
			//choice 1: Turn the knob to the right. increase ML by 1.
			//choice 2: Turn the knob to the left. reduces ML by 1. can not reduce below 10 but will adjust a hidden counter
			//choice 3: Drop a grey goo ring into the slot. destroy it and gain +300 assorted goo items
			//choice 4: Leave the console alone
			run_choice(1);
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
