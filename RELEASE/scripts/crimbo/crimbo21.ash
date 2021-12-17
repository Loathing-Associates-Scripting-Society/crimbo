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
	//there seems to be some unreliability on this value so add 1 to the final value
	return 6 + ($location[Site Alpha Dormitory].turns_spent / 3);
}

void visit_sauna()
{
	if(have_effect($effect[Sauna-Fresh]) > 0)
	{
		return;		//already visited
	}
	visit_url("place.php?whichplace=northpole&action=np_sauna");
	run_choice(1);
}

boolean crimbo_loop()
{
	//return true when changes are made to restart the loop.
	//return false to end the loop.
	auto_interruptCheck();
	
	resetState();
	
	//cold res buffs
	horsePale();	//we want the cold res
	buffMaintain($effect[Astral shell], 0, 1, 1);
	buffMaintain($effect[Elemental saucesphere], 0, 1, 1);
	buffMaintain($effect[Scarysauce], 0, 1, 1);
	
	//item buffs
	asdonBuff($effect[Driving Observantly]);	//+50% item drops
	buffMaintain($effect[Fat Leon\'s Phat Loot Lyric], 0, 1, 1);		//+20 item drop
	buffMaintain($effect[Singer\'s Faithful Ocelot], 0, 1, 1);			//+10 item drop
	
	//choose where to adv. currently only one location available
	//requires scaling cold res. start at 5 and increase by 1 every 3 adv done there
	location goal = $location[Site Alpha Dormitory];
	
	string maximizer_override = "100 cold res,item,switch exotic parrot,switch mu,switch trick-or-treating tot";
	set_property("auto_maximize_current", maximizer_override);
	equipMaximizedGear();
	autoMaximize(maximizer_override, 0, 0, true);
	int coldResist = numeric_modifier("Cold Resistance");
	int coldness = coldness();
	
	if(coldResist < coldness)
	{
		visit_sauna();
	}

	//finally adventure
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
	backupSetting("betweenBattleScript", "scripts/crimbo/crimbo_pre_adv.ash");
	backupSetting("afterAdventureScript", "scripts/crimbo/crimbo_post_adv.ash");
	backupSetting("choiceAdventureScript", "scripts/autoscend/auto_choice_adv.ash");
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
