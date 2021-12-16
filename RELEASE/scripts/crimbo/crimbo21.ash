import <scripts/autoscend.ash>

void crimbo_settings_defaults()
{
	//set default values for settings which have not yet been configured
	//defaultConfig("cribo_setting", "default_value");
}

void spam_url(string target)
{
	//hit a url repeatedly to exhaust all the dialog. stop when the results are the same as before.
	string page_text_old;
	string page_text_new = visit_url(target);
	int protect = 0;
	auto_log_debug("spam_url starting for: " +target);
	while(page_text_old != page_text_new)
	{
		page_text_old = page_text_new;		//the new becomes the old
		page_text_new = visit_url(target);
		protect++;
		if(protect > 10)
		{
			print("spam_url detected infinite loop when trying to repeat visit the url:", "red");
			print(target, "red");
			print("correcting by halting the loop", "red");
			break;
		}
	}
	auto_log_debug("spam_url finished successfully");
}

void crimbo_quest_start()
{
	//starts the crimbo quests
	if(get_property("_crimbo21_quest_started").to_boolean())
	{
		return;		//already done today
	}
	
	spam_url("place.php?whichplace=crimbo21&action=c21_abuela");
	spam_url("place.php?whichplace=northpole&action=np_bonfire");
	
	set_property("_crimbo21_quest_started", true);
}

boolean cAdv(int num, location loc, string option)
{
	remove_property("auto_combatHandler");
	set_property("auto_diag_round", 0);
	set_property("nextAdventure", loc);

	// adv1 can erroneously return false for "choiceless" non-combats
	// see https://kolmafia.us/showthread.php?25370-adv1-returns-false-for-quot-choiceless-quot-choice-adventures
	// undo all this when (if?) that ever gets fixed
	string previousEncounter = get_property("lastEncounter");
	int turncount = my_turncount();
	boolean advReturn = adv1(loc, -1, option);
	if (!advReturn)
	{
		auto_log_debug("adv1 returned false for some reason. Did we actually adventure though?", "blue");
		if (get_property("lastEncounter") != previousEncounter)
		{
			auto_log_debug(`Looks like we may have adventured, lastEncounter was {previousEncounter}, now {get_property("lastEncounter")}`, "blue");
			advReturn = true;
		}
		if (my_turncount() > turncount)
		{
			auto_log_debug(`Looks like we may have adventured, turncount was {turncount}, now {my_turncount()}`, "blue");
			advReturn = true;
		}
	}
	return advReturn;
}

boolean cAdv(location loc)
{
	return cAdv(1, loc, "");
}

int coldness()
{
	//[Site Alpha Dormitory] has scaling cold res requirement. starting at 5 and increased by 1 every 3 adv spent there.
	return 5 + ($location[Site Alpha Dormitory].turns_spent / 3);
}

boolean crimbo_loop()
{
	//return true when changes are made to restart the loop.
	//return false to end the loop.
	
	resetState();
	auto_interruptCheck();
	int coldness = coldness();
	
	horsePale();	//we want the cold res
	asdonBuff($effect[Driving Observantly]);	//+50% item drops
	
	//choose where to adv. currently only one location available
	//requires scaling cold res. start at 5 and increase by 1 every 3 adv done there
	location goal = $location[Site Alpha Dormitory];
	
	//prepare for coldness
	int[element] resGoal;
	resGoal[$element[cold]] = coldness;
	if(!provideResistances(resGoal, goal, true))
	{
		abort("Failed to get " +coldness+ " cold resist");
	}
	
	//finally adventure
	equipMaximizedGear();
	if(cAdv(goal)) return true;
	abort("Failed to adventure in [" + goal + "]");
	return false;
}

void main(int adv_to_use)
{
	if(!can_interact())
	{
		abort("Attempting to run crimbo 2021 while in softcore or hardcore is not currently supported");
	}
	crimbo_settings_defaults();
	crimbo_quest_start();
	
	backupSetting("printStackOnAbort", true);
	backupSetting("promptAboutCrafting", 0);
	backupSetting("breakableHandling", 4);
	backupSetting("dontStopForCounters", true);
	backupSetting("maximizerCombinationLimit", "100000");
	backupSetting("afterAdventureScript", "scripts/autoscend/auto_post_adv.ash");
	backupSetting("choiceAdventureScript", "scripts/autoscend/auto_choice_adv.ash");
	backupSetting("betweenBattleScript", "scripts/autoscend/auto_pre_adv.ash");
	backupSetting("recoveryScript", "");
	backupSetting("counterScript", "");
	backupSetting("battleAction", "custom combat script");
	backupSetting("currentMood", "apathetic");
	backupSetting("logPreferenceChange", "true");
	backupSetting("logPreferenceChangeFilter", "maximizerMRUList,testudinalTeachings,auto_maximize_current");
	
	int adv_initial = my_session_adv();
	
	//primary loop
	int adv_spent = 0;
	try
	{
		while(adv_to_use > adv_spent && my_adventures() > 0 && crimbo_loop())
		{
			adv_spent = my_session_adv() - adv_initial;
		}
	}
	finally
	{
		restoreAllSettings();
	}
}
