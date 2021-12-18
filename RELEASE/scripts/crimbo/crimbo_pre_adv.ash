import<autoscend.ash>

void print_footer()
{
	auto_log_info("[" +my_class()+ "] @ path of [" +my_path()+ "]", "blue");
	
	string next_line = "HP: " +my_hp()+ "/" +my_maxhp()+ ", MP: " +my_mp()+ "/" +my_maxmp()+ ", Meat: " +my_meat();
	switch(my_class())
	{
		case $class[Seal Clubber]:
			next_line += ", Fury: " +my_fury()+ "/" +my_maxfury();
			break;
		case $class[Turtle Tamer]:
			foreach ttbless in $effects[Blessing of the War Snapper, Grand Blessing of the War Snapper, Glorious Blessing of the War Snapper, Blessing of She-Who-Was, Grand Blessing of She-Who-Was, Glorious Blessing of She-Who-Was, Blessing of the Storm Tortoise, Grand Blessing of the Storm Tortoise, Glorious Blessing of the Storm Tortoise]
			{
				if(have_effect(ttbless) > 0)
				{
					next_line += ", Blessing: " +ttbless;
				}
			}
			break;	
		case $class[Sauceror]:
			next_line += ", Soulsauce: " +my_soulsauce();
			break;
	}
	auto_log_info(next_line, "blue");
	
	int bonus_mus = my_buffedstat($stat[muscle]) - my_basestat($stat[muscle]);
	int bonus_mys = my_buffedstat($stat[mysticality]) - my_basestat($stat[mysticality]);
	int bonus_mox = my_buffedstat($stat[moxie]) - my_basestat($stat[moxie]);
	auto_log_info("mus: " +my_basestat($stat[muscle])+ " + " +bonus_mus+
	". mys: " +my_basestat($stat[mysticality])+ " + " +bonus_mys+
	". mox: " +my_basestat($stat[moxie])+ " + " +bonus_mox, "blue");
	
	next_line = "";
	if(pathHasFamiliar())
	{
		next_line += "Familiar: " +my_familiar()+ " @ " + familiar_weight(my_familiar()) + " + " + weight_adjustment() + "lbs. ";
	}
	if(my_class() == $class[Pastamancer])
	{
		next_line += "Thrall: [" +my_thrall()+ "] @ level " +my_thrall().level;
	}
	if(isActuallyEd())
	{
		next_line += "Servant: [" +my_servant()+ "] @ level " +my_servant().level;
	}
	if(my_class() == $class[Avatar of Jarlsberg])
	{
		next_line += "Companion: [" +my_companion();
	}
	auto_log_info(next_line, "blue");
	
	auto_log_info("ML: " + monster_level_adjustment() + " Encounter: " + combat_rate_modifier() + " Init: " + initiative_modifier(), "blue");
	auto_log_info("Exp Bonus: " + experience_bonus() + " Meat Drop: " + meat_drop_modifier() + " Item Drop: " + item_drop_modifier(), "blue");
	auto_log_info("Resists: " + numeric_modifier("Hot Resistance") + "/" + numeric_modifier("Cold Resistance") + "/" + numeric_modifier("Stench Resistance") + "/" + numeric_modifier("Spooky Resistance") + "/" + numeric_modifier("Sleaze Resistance"), "blue");
	
	//current equipment
	next_line = "equipment: ";
	foreach sl in $slots[]
	{
		if($slots[hat, weapon, off-hand, back, shirt, pants, acc1, acc2, acc3, familiar] contains sl)		//we always want to print the core slots
		{
			next_line += sl+ "=[" +equipped_item(sl)+ "]. ";
		}
		else if(equipped_item(sl) != $item[none])		//other slots should only be printed if they contain something
		{
			next_line += sl+ "=[" +equipped_item(sl)+ "]. ";
		}
	}
	auto_log_info(next_line, "blue");
}

void auto_ghost_prep(location place)
{
	//if place contains physically immune enemies then we need to be prepared to deal non physical damage.
	if(!is_ghost_in_zone(place))
	{
		return;		//no ghosts no problem
	}
	if(in_plumber())
	{
		return;		//these paths either have their own ghost handling. or can always kill ghosts
	}
	if(get_property("youRobotBottom").to_int() == 2)
	{
		return;		//you robot with a rocket crotch. deals fire damage to kill ghosts.
	}
	//a few iconic spells per avatar is ok. no need to be too exhaustive
	foreach sk in $skills[
		Saucestorm, saucegeyser,	//base classes
		Storm of the Scarab,		//actually ed the undying
		Boil,						//avatar of jarlsberg
		Bilious Burst				//zombie slayer
		]
	{
		if(auto_have_skill(sk))
		{
			acquireMP(32, 1000);		//make sure we actually have the MP to cast spells
		}
		if(canUse(sk)) return;	//we can kill them with a spell
	}
	
	int m_hot = 1;
	int m_cold = 1;
	int m_spooky = 1;
	int m_sleaze = 1;
	int m_stench = 1;
	foreach idx, mob in get_monsters(place)
	{
		if(mob.physical_resistance >= 80)
		{
			switch(monster_element(mob))
			{
			case $element[hot]:
				m_hot = 0;
				m_sleaze = 2;
				m_stench = 2;
				break;
			case $element[cold]:
				m_cold = 0;
				m_hot = 2;
				m_spooky = 2;
				break;
			case $element[spooky]:
				m_spooky = 0;
				m_hot = 2;
				m_stench = 2;
				break;
			case $element[sleaze]:
				m_sleaze = 0;
				m_cold = 2;
				m_spooky = 2;
				break;
			case $element[stench]:
				m_stench = 0;
				m_sleaze = 2;
				m_cold = 2;
				break;
			}
		}
	}
	
	string max_with;
	int bonus;
	if(m_hot != 0) max_with += "," +10*m_hot+ "hot dmg";
	if(m_cold != 0) max_with += "," +10*m_cold+ "cold dmg";
	if(m_spooky != 0) max_with += "," +10*m_spooky+ "spooky dmg";
	if(m_sleaze != 0) max_with += "," +10*m_sleaze+ "sleaze dmg";
	if(m_stench != 0) max_with += "," +10*m_stench+ "stench dmg";
	
	simMaximizeWith(max_with);
	if(m_hot != 0) bonus += simValue("hot damage");
	if(m_cold != 0) bonus += simValue("cold damage");
	if(m_spooky != 0) bonus += simValue("spooky damage");
	if(m_sleaze != 0) bonus += simValue("sleaze damage");
	if(m_stench != 0) bonus += simValue("stench damage");
	
	if(bonus > 9)
	{
		addToMaximize(max_with);
		return;
	}

	abort("I was about to head into [" +place+ "] which contains ghosts. I can not damage those");
}

boolean crimbo_pre_adventure()
{
	location place = my_location();
	if(get_property("auto_disableAdventureHandling").to_boolean())
	{
		auto_log_info("Preadventure skipped by standard adventure handler.", "green");
		return true;
	}
	auto_log_info("Starting preadventure script...", "green");
	auto_log_debug("Adventuring at " +place, "green");
	
	preAdvUpdateFamiliar(place);

	if((get_property("_bittycar") == "") && (item_amount($item[Bittycar Meatcar]) > 0))
	{
		use(1, $item[Bittycar Meatcar]);
	}

	if((place == $location[The Broodling Grounds]) && (my_class() == $class[Seal Clubber]))
	{
		uneffect($effect[Spiky Shell]);
		uneffect($effect[Scarysauce]);
	}

	if($locations[Next to that Barrel with something Burning In It, Near an Abandoned Refrigerator, Over where the Old Tires Are, Out by that Rusted-Out Car] contains place)
	{
		uneffect($effect[Spiky Shell]);
		uneffect($effect[Scarysauce]);
	}

	// this calls the appropriate provider for +combat or -combat depending on the zone we are about to adventure in..
	boolean burningDelay = ((auto_voteMonster(true) || isOverdueDigitize() || auto_sausageGoblin() || auto_backupTarget()) && place == solveDelayZone());
	generic_t combatModifier = zone_combatMod(place);
	if (combatModifier._boolean && !burningDelay && !auto_haveQueuedForcedNonCombat()) {
		acquireCombatMods(combatModifier._int, true);
	}

	horsePreAdventure();
	auto_snapperPreAdventure(place);

	// Last minute switching for garbage tote. But only if nothing called on januaryToteAcquire this turn.
	if(!get_property("auto_januaryToteAcquireCalledThisTurn").to_boolean())
	{
		januaryToteAcquire($item[Wad Of Used Tape]);
	}

	// EQUIP MAXIMIZED GEAR
	auto_ghost_prep(place);
	maximize(get_property("auto_maximize_current"), 2500, 0, false);
	cli_execute("checkpoint clear");
	executeFlavour();

	if (my_hp() <= (my_maxhp() * 0.75)) {
		acquireHP();
	}
	acquireMP(32, 1000);

	if (my_inebriety() > inebriety_limit())
	{
		if($locations[The Tunnel of L.O.V.E.] contains place)
		{
			auto_log_info("Trying to adv in [" +place+ "] while overdrunk... is actually permitted", "blue");
		}
		else abort("Trying to adv in [" +place+ "] while overdrunk... Stop it.");
	}
	
	set_property("auto_priorLocation", place);
	auto_log_info("Pre Adventure at " + place + " done, beep.", "blue");

	print_footer();
	return true;
}

void main()
{
	boolean ret = false;
	try
	{
		ret = crimbo_pre_adventure();
	}
	finally
	{
		if (!ret)
		{
			auto_log_error("Error running auto_pre_adv.ash, setting auto_interrupt=true");
			set_property("auto_interrupt", true);
		}
		auto_interruptCheck();
	}
}
