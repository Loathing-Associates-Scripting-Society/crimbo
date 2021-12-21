import <scripts/autoscend.ash>

void crimbo_settings_defaults()
{
	//set default values for settings which have not yet been configured
	defaultConfig("crimbo21_ratio_animal", 1);
	defaultConfig("crimbo21_ratio_vegetable", 1);
	defaultConfig("crimbo21_ratio_mineral", 1);
	rename_property("crimbo21_consume","crimbo21_food");
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
	visit_url("place.php?whichplace=northpole");
	spam_url("place.php?whichplace=northpole&action=np_bonfire");
	
	visit_url("place.php?whichplace=northpole&action=np_sauna");
	run_choice(2);	//leave
	spam_url("place.php?whichplace=northpole&action=np_bonfire");
	
	visit_url("place.php?whichplace=northpole&action=np_foodlab");
	run_choice(2);	//leave
	spam_url("place.php?whichplace=northpole&action=np_bonfire");
	
	visit_url("place.php?whichplace=northpole&action=np_boozelab");
	run_choice(2);	//leave
	spam_url("place.php?whichplace=northpole&action=np_bonfire");
	
	visit_url("place.php?whichplace=northpole&action=np_spleenlab");
	run_choice(2);	//leave
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
	int visits = get_property("_crimbo21_greenhouse").to_int() + get_property("_crimbo21_dormitory").to_int();
	int adjust = get_property("_crimbo21_cold_adjust").to_int();
	return 6 + (visits / 3) + adjust;
}

void coldness_correction()
{
	//if coldness becomes desynced we need to fix it with an adjustment value
	int actual_coldness = get_property("_crimbo21ColdResistance").to_int();
	if(actual_coldness == 0)
	{
		return;		//nothing to fix yet
	}
	
	int predicted_value = (get_property("_crimbo21_greenhouse").to_int() + get_property("_crimbo21_dormitory").to_int()) / 3;
	predicted_value += 5;
	int diff = actual_coldness - predicted_value;
	auto_log_debug("Compensating for coldness. adjust value = " +diff);
	set_property("_crimbo21_cold_adjust", diff);
	remove_property("_crimbo21ColdResistance");
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

void coldFam()
{
	//we need a cold resistent familiar
	familiar resfam = $familiar[none];
	foreach fam in $familiars[Trick-or-Treating Tot, Mu, Exotic Parrot]
	{
		if(auto_have_familiar(fam))
		{
			resfam = fam;
			break;
		}
	}
	if(resfam != $familiar[none])
	{
		handleFamiliar(resfam);
		use_familiar(resfam);
		if(resfam == $familiar[Trick-or-Treating Tot])
		{
			cli_execute("acquire 1 li'l candy corn costume");
		}
	}
}

location crimbo21_goal()
{
	//determine where we should adventure
	location retval = $location[none];
	
	int anim_rat = get_property("crimbo21_ratio_animal").to_int();
	int vege_rat = get_property("crimbo21_ratio_vegetable").to_int();
	int mine_rat = get_property("crimbo21_ratio_mineral").to_int();
	boolean skip_dormitory = anim_rat < 1;
	boolean skip_greenhouse = vege_rat < 1;
	boolean skip_quarry = mine_rat < 1;
	
	//find the relative values while preventing division by zero
	float anim_val = -1;
	float vege_val = -1;
	float mine_val = -1;
	if(!skip_dormitory) anim_val = item_amount($item[gooified animal matter]) / anim_rat;
	if(!skip_greenhouse) vege_val = item_amount($item[gooified vegetable matter]) / vege_rat;
	if(!skip_quarry) mine_val = item_amount($item[gooified mineral matter]) / mine_val;
	
	//choose lowest val as target. so long as it is not skipped
	if(!skip_dormitory)
	{
		retval = $location[site alpha dormitory];
	}
	if(!skip_greenhouse)
	{
		if(retval == $location[none] || vege_val < anim_val)
		{
			retval = $location[site alpha greenhouse];
		}
	}
	if(!skip_quarry)
	{
		if(retval == $location[none] ||
		(retval == $location[site alpha dormitory] && mine_val < anim_val) ||
		(retval == $location[site alpha greenhouse] && mine_val < vege_val))
		{
			retval = $location[site alpha quarry];
		}
	}
	return retval;
}

void crimbo21_food()
{
	//crimbo21 has epic quality experimental food buyable as a quest item. once you eat one you can get another
	//you may decide you want to gorge on it while it is available
	if(!get_property("crimbo21_food").to_boolean())
	{
		return;		//user did not opt in
	}
	if(stomach_left() < 3)
	{
		return;		//not enough space to eat it
	}
	consumeMilkOfMagnesiumIfUnused();
	
	item exp = $item[[experimental crimbo food]];
	if(item_amount(exp) == 0 && item_amount($item[gooified animal matter]) >= 5)
	{
		visit_url("place.php?whichplace=northpole&action=np_foodlab");
		run_choice(1);	//buy food
	}
	if(item_amount(exp) == 0) abort("Mysteriously failed to acquire " +exp);
	
	eat(exp);
}

void crimbo21_drink()
{
	//crimbo21 has good quality experimental drink buyable as a quest item. once you eat one you can get another
	//you may decide you want to gorge on it while it is available
	if(!get_property("crimbo21_drink").to_boolean())
	{
		return;		//user did not opt in
	}
	if(my_familiar() == $familiar[Stooper] && pathAllowsChangingFamiliar())
	{
		auto_log_info("Avoiding stooper stupor...", "blue");
		familiar fam = (is100FamRun() ? get_property("auto_100familiar").to_familiar() : $familiar[Mosquito]);
		use_familiar(fam);
	}
	if(inebriety_left() < 3)
	{
		return;		//not enough space to drink it
	}
	
	item exp = $item[[experimental crimbo booze]];
	if(item_amount(exp) == 0 && item_amount($item[gooified vegetable matter]) >= 5)
	{
		visit_url("place.php?whichplace=northpole&action=np_boozelab");
		run_choice(1);	//buy food
	}
	if(item_amount(exp) == 0) abort("Mysteriously failed to acquire " +exp);
	
	if(canOde(exp) && auto_have_skill($skill[The Ode to Booze]))
	{
		shrugAT($effect[Ode to Booze]);
		acquireMP(mp_cost($skill[The Ode to Booze]), 0);
		buffMaintain($effect[Ode to Booze]);
	}
	drink(exp);
}

void crimbo21_consume()
{
	crimbo21_food();
	crimbo21_drink();
}

boolean crimbo_loop()
{
	//return true when changes are made to restart the loop.
	//return false to end the loop.
	auto_interruptCheck();
	
	resetState();
	
	crimbo21_consume();
	if(get_property("crimbo_do_free_combats").to_boolean())
	{
		if(LX_freeCombats(true)) return true;
	}
	
	//cold res buffs
	horsePale();	//we want the cold res
	buffMaintain($effect[Astral shell], 0, 1, 1);
	buffMaintain($effect[Elemental saucesphere], 0, 1, 1);
	buffMaintain($effect[Scarysauce], 0, 1, 1);
	
	//item buffs
	asdonBuff($effect[Driving Observantly]);	//+50% item drops
	buffMaintain($effect[Fat Leon\'s Phat Loot Lyric], 0, 1, 1);		//+20 item drop
	buffMaintain($effect[Singer\'s Faithful Ocelot], 0, 1, 1);			//+10 item drop
	
	//choose where to adv based on user configured ratio.
	//requires scaling cold res. start at 5 and increase by 1 every 3 adv done there
	location goal = crimbo21_goal();
	if(goal == $location[none]) abort("We have no target locaton to adv");
	coldFam();		//get a cold res familiar if possible.
	
	//configure maximizer
	string maximizer_override = "5item,200cold res";
	set_property("auto_maximize_current", maximizer_override);
	maximize(get_property("auto_maximize_current"), 2500, 0, false);	//maximize. needed for provide as well.
	
	int coldResist = numeric_modifier("Cold Resistance");
	int coldness = coldness();
	auto_log_debug("Attempting to acquire " +coldness+ " cold res");
	int [element] res;
	res[$element[cold]] = coldness;
	provideResistances(res, goal, false);		//do not switch outfit here. maximizer handles it better.
	
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
	coldness_correction();
	crimbo21_consume();		//in case starting at 0 adv
	
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
