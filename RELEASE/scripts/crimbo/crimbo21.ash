import <scripts/autoscend/autoscend.ash>

void crimbo_settings_defaults()
{
	//set default values for settings which have not yet been configured
	//defaultConfig("cribo_setting", "default_value");
}

boolean crimbo_loop()
{
	//return true when changes are made to restart the loop.
	//return false to end the loop.
	
	resetState();
	auto_interruptCheck();
	
	//getHorse("dark");		//+meat and also -5 combat
	asdonBuff($effect[Driving Observantly]);	//+50% item drops
	
	location goal = $location[Site Alpha Dormitory];		//currently only place we can adv
	
	//finally adventure
	if(autoAdv(goal)) return true;
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
