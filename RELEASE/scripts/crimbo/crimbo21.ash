import <scripts/autoscend.ash>

void crimbo_settings_defaults()
{
	//set default values for settings which have not yet been configured
	remove_property("crimbo21_ratio_animal");
	remove_property("crimbo21_ratio_vegetable");
	remove_property("crimbo21_ratio_mineral");
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
	
	//MCD is bad @ [site alpha primary lab]
	if(current_mcd() != 0)
	{
		change_mcd(0);
	}
	
	crimbo21_consume();
	if(get_property("crimbo_do_free_combats").to_boolean())
	{
		if(LX_freeCombats(true)) return true;
	}
	
	if(LX_ghostBusting()) return true;
	
	//cold res buffs
	horsePale();	//we want the cold res
	buffMaintain($effect[Astral shell]);
	buffMaintain($effect[Elemental saucesphere]);
	buffMaintain($effect[Scarysauce]);
	buffMaintain($effect[Scariersauce]);
	
	//item buffs
	asdonBuff($effect[Driving Observantly]);					//+50% item drops
	buffMaintain($effect[Fat Leon\'s Phat Loot Lyric]);			//+20 item drop
	buffMaintain($effect[Singer\'s Faithful Ocelot]);			//+10 item drop
	
	//choose where to adv based on user configured ratio.
	//requires scaling cold res. start at 5 and increase by 1 every 3 adv done there
	location goal = $location[site alpha primary lab];
	coldFam();		//get a cold res familiar if possible.
	
	//configure maximizer
	set_property("auto_maximize_current", "cold res");
	if(possessEquipment($item[goo magnet]))
	{
		autoForceEquip($item[goo magnet]);
	}
	//up to 2 [ert grey goo ring] may be equipped to increase the number of goo drops you get.
	item gring = $item[ert grey goo ring];
	int gring_amt = item_amount(gring) + equipped_amount(gring);
	if(gring_amt > 1)
	{
		autoForceEquip($slot[acc1], gring);
		autoForceEquip($slot[acc2], gring);
	}
	else if(gring_amt == 1)
	{
		autoForceEquip($slot[acc1], gring);
	}
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
	int autoscend_revision = svn_info("autoscend").revision;
	if(autoscend_revision < 1)
	{
		print("Missing dependency script autoscend:", "red");
		abort("https://github.com/Loathing-Associates-Scripting-Society/autoscend");
	}
	else if(autoscend_revision < 5130)
	{
		abort("Your autoscend version is too old. Try gCLI command svn update. if this does not fix the problem then you need to reinstall autoscend");
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
