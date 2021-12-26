# crimbo
Script for automating Crimbo in Kingdom of Loathing

## Dependencies
When installed it will also install the following dependencies:
```
https://github.com/Loathing-Associates-Scripting-Society/autoscend/branches/master/RELEASE/
```

## Installation

Run this command in the gCLI:
```
svn checkout https://github.com/Loathing-Associates-Scripting-Society/crimbo/trunk/RELEASE/
```
Will require [a recent build of KoLMafia](http://builds.kolmafia.us/job/Kolmafia/lastSuccessfulBuild/).

## Uninstall

Run this command in the gCLI:
```
svn delete crimbo
```

## crimbo21.ash

A script for doing the Crimbo 2021 event.

Run this command in the gCLI:
```
crimbo21 X
```
Where X = number of adv you are willing to spend

Or you can click on it from the dropdown scripts menu to be asked how many adventures to spend in a popup.
You need to configure a custom combat script for fighting the enemies. My personal script (for sauceror) is:

```
[ default ]
scrollwhendone
if sauceror
    skill curse of weaksauce
endif
special action
skill micrometeorite
skill saucegeyser
```
