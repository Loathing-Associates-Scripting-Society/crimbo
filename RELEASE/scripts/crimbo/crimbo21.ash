import <scripts/autoscend.ash>

//define some shorthand for items
item goo_ani = $item[gooified animal matter];
item goo_veg = $item[gooified vegetable matter];
item goo_min = $item[gooified mineral matter];

void crimbo_settings_defaults()
{
	//set default values for settings which have not yet been configured
	remove_property("crimbo21_ratio_animal");
	remove_property("crimbo21_ratio_vegetable");
	remove_property("crimbo21_ratio_mineral");
	rename_property("crimbo21_consume","crimbo21_food");
	
	//Desired target tons for enemies in [Site Alpha Primary Lab]. Tonnage boosts ML significantly. Min value is 10. Every 3 tons above 10 will add 1 extra gooified drop. Enemies become stun immune @30? tons. @43 tons they become stagger immune and have about 50k attack and 100k hp.
	defaultConfig("crimbo21_tons_desired", 28);		//+6 items dropped without becomming immune to stuns
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
	if(!get_property("crimbo_advance_plot").to_boolean())
	{
		return;		//user did not opt in
	}
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
	//adv locations have scaling cold res requirement. starting at 5 and increased by 1 every 3 adv spent in any of the locations.
	//there seems to be some unreliability on this value so add 1 to the final value
	int visits = get_property("_crimbo21_adv").to_int();
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
	
	int predicted_value = 5 + get_property("_crimbo21_adv").to_int();
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
	if(item_amount(exp) == 0)
	{
		if(item_amount(goo_ani) >= 5)
		{
			visit_url("place.php?whichplace=northpole&action=np_foodlab");
			run_choice(1);	//buy food
		}
		else return;	//we can not afford to buy it right now
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
	if(item_amount(exp) == 0)
	{
		if(item_amount(goo_veg) >= 5)
		{
			visit_url("place.php?whichplace=northpole&action=np_boozelab");
			run_choice(1);	//buy food
		}
		else return;	//we can not afford to buy it right now
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

boolean can_afford_goo(int id)
{
	//do we have enough animal, vegetable, and mineral matter
	int ani = 0;
	int veg = 0;
	int min = 0;
	switch(id)
	{
		case 1: ani = 30; break;
		case 2: veg = 30; break;
		case 3: min = 30; break;
		case 4: ani = 15; veg = 15; break;
		case 5: veg = 15; min = 15; break;
		case 6: min = 15; ani = 15; break;
		case 7: ani = 10; veg = 10; min = 10; break;
	}
	return item_amount(goo_ani) >= ani && item_amount(goo_veg) >= veg && item_amount(goo_min) >= min;
}

void spend_goo()
{
	//spend your gooified matter in [Gift Fabrication Lab]
	if(!get_property("crimbo21_spend").to_boolean())
	{
		return;		//user did not opt in
	}
	
	//id:
	//1 => Animal (30)
	//2 => Vegetable (30)
	//3 => Mineral (30)
	//4 => Animal + Vegetable (15 each)
	//5 => Vegetable + Mineral (15 each)
	//6 => Mineral + Animal (15 each)
	//7 => A little bit of everything (10 each)
	//8 => Leave. redundant. can navigate away.
	
	boolean spend = true;
	
	int buy_id = 0;
	while(spend)
	{
		print("Delaying for 1 second before spending your goo. You can halt this by clicking the [safely stop scripts] button in the GUI");
		wait(1);
		auto_interruptCheck();	//abort if user hit [safely stop scripts] button
		
		spend = false;		//will disable the loop if nothing is found.
		int amt_wanted = 0;
		int test_id = 0;
		item test_item = $item[none];
		boolean want = false;
		int buy_id = 0;					//the id of the rare item we intend to buy
		item buy_item = $item[none];	//the item name of the rare item we intend to buy
		int buy_have = 0;				//the amount you currently have of the target buying item
		
		//Animal (30)
		amt_wanted = get_property("crimbo21_giftcap_1").to_int();
		test_id = 1;
		test_item = $item[festive egg sac];
		if(can_afford_goo(test_id) && (amt_wanted < 0 || item_amount(test_item) < amt_wanted))
		{
			if(buy_id == 0 || item_amount(test_item) < item_amount(buy_item))
			{
				spend = true;
				buy_id = test_id;
				buy_item = test_item;
				buy_have = item_amount(test_item);
			}
		}
		
		//Vegetable (30)
		amt_wanted = get_property("crimbo21_giftcap_2").to_int();
		test_id = 2;
		test_item = $item[the Crymbich Manuscript];
		if(can_afford_goo(test_id) && (amt_wanted < 0 || item_amount(test_item) < amt_wanted))
		{
			if(buy_id == 0 || item_amount(test_item) < item_amount(buy_item))
			{
				spend = true;
				buy_id = test_id;
				buy_item = test_item;
				buy_have = item_amount(test_item);
			}
		}
		
		//Mineral (30)
		amt_wanted = get_property("crimbo21_giftcap_3").to_int();
		test_id = 3;
		test_item = $item[synthetic rock];
		if(can_afford_goo(test_id) && (amt_wanted < 0 || item_amount(test_item) < amt_wanted))
		{
			if(buy_id == 0 || item_amount(test_item) < item_amount(buy_item))
			{
				spend = true;
				buy_id = test_id;
				buy_item = test_item;
				buy_have = item_amount(test_item);
			}
		}
		
		//Animal + Vegetable (15 each)
		amt_wanted = get_property("crimbo21_giftcap_4").to_int();
		test_id = 4;
		test_item = $item[carnivorous potted plant];
		if(can_afford_goo(test_id) && (amt_wanted < 0 || item_amount(test_item) < amt_wanted))
		{
			if(buy_id == 0 || item_amount(test_item) < item_amount(buy_item))
			{
				spend = true;
				buy_id = test_id;
				buy_item = test_item;
				buy_have = item_amount(test_item);
			}
		}
		
		//Vegetable + Mineral (15 each)
		amt_wanted = get_property("crimbo21_giftcap_5").to_int();
		test_id = 5;
		test_item = $item[potato alarm clock];
		if(can_afford_goo(test_id) && (amt_wanted < 0 || item_amount(test_item) < amt_wanted))
		{
			if(buy_id == 0 || item_amount(test_item) < item_amount(buy_item))
			{
				spend = true;
				buy_id = test_id;
				buy_item = test_item;
				buy_have = item_amount(test_item);
			}
		}
		
		//Mineral + Animal (15 each)
		amt_wanted = get_property("crimbo21_giftcap_6").to_int();
		test_id = 6;
		test_item = $item[boxed gumball machine];
		if(can_afford_goo(test_id) && (amt_wanted < 0 || item_amount(test_item) < amt_wanted))
		{
			if(buy_id == 0 || item_amount(test_item) < item_amount(buy_item))
			{
				spend = true;
				buy_id = test_id;
				buy_item = test_item;
				buy_have = item_amount(test_item);
			}
		}
		
		//A little bit of everything (10 each)
		amt_wanted = get_property("crimbo21_giftcap_7").to_int();
		test_id = 7;
		test_item = $item[can of mixed everything];
		if(can_afford_goo(test_id) && (amt_wanted < 0 || item_amount(test_item) < amt_wanted))
		{
			if(buy_id == 0 || item_amount(test_item) < item_amount(buy_item))
			{
				spend = true;
				buy_id = test_id;
				buy_item = test_item;
				buy_have = item_amount(test_item);
			}
		}
		
		if(spend)
		{
			visit_url("place.php?whichplace=northpole&action=np_toylab");
			run_choice(buy_id);
		}
	}
}

int coldRes()
{
	return numeric_modifier("Cold Resistance");
}

void prepare_cold_res()
{
	auto_log_debug("Attempting to acquire " +coldness()+ " cold res");
	int [element] res;
	res[$element[cold]] = coldness();
	provideResistances(res, goal, false);		//do not switch outfit here. maximizer handles it better.
	
	boolean needed()
	{
		return coldRes() < coldness();
	}
	
	foreach ef in $effects[Oiled-Up, Red Door Syndrome, Spooky Hands, Insulated Trousers, Berry Elemental]
	{
		if(needed())
		{
			buffMaintain(ef);
		}
	}
	
	if(needed())
	{
		rethinkingCandy($effect[Synthesis: Cold]);
	}
	
	if(needed())
	{
		visit_sauna();
	}
}

boolean crimbo_loop()
{
	//return true when changes are made to restart the loop.
	//return false to end the loop.
	auto_interruptCheck();
	spend_goo();
	
	resetState();
	
	//MCD is bad @ [site alpha primary lab]
	if(current_mcd() != 0)
	{
		change_mcd(0);
	}
	uneffect($effect[Ur-kel\'s Aria of Annoyance]);		//+ML is unwanted
	uneffect($effect[[1457]Blood Sugar Sauce Magic]);	//convert HP to MP is unwanted. offclass version. 10%
	uneffect($effect[[1458]Blood Sugar Sauce Magic]);	//convert HP to MP is unwanted. sauceror version. 30%
	
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
	buffMaintain($effect[Feeling Peaceful]);			//+2 all res. +10 DR, +100 DA. unsupported?
	
	//other buffs
	//asdonBuff($effect[Driving Observantly]);					//+50% item drops. obsolete in lab
	//buffMaintain($effect[Fat Leon\'s Phat Loot Lyric]);		//+20 item drop. obsolete in lab
	//buffMaintain($effect[Singer\'s Faithful Ocelot]);			//+10 item drop. obsolete in lab
	buffMaintain($effect[Carol of the Hells]);					//+100% spell damage
	buffMaintain($effect[Big]);									//+20% all stats
	buffMaintain($effect[Triple-Sized]);						//+200% all stats
	buffMaintain($effect[blood bubble]);						//blocks 1st hit in combat
	
	//choose where to adv based on user configured ratio.
	//requires scaling cold res. start at 5 and increase by 1 every 3 adv done there
	location goal = $location[site alpha primary lab];
	coldFam();		//get a cold res familiar if possible.
	
	//configure maximizer
	//we want to avoid maximizer taking on bad traits like -spell damage and +ml. So we include their opposite but at a tiny fraction
	string maximizer_override = "-ml,+spell damage,1000cold res";
	set_property("auto_maximize_current", maximizer_override);
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
	
	prepare_cold_res();
	acquireHP();

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
	backupSetting("choiceAdventureScript", "scripts/crimbo/crimbo_choice_adv.ash");
	backupSetting("recoveryScript", "");
	backupSetting("counterScript", "");
	backupSetting("battleAction", "custom combat script");
	backupSetting("logPreferenceChange", "true");
	backupSetting("logPreferenceChangeFilter", "maximizerMRUList,testudinalTeachings,auto_maximize_current");
	
	int adv_initial = my_session_adv();
	
	spend_goo();
	
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
