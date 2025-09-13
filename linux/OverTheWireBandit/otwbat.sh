#!/bin/bash

#OverTheWire - Bandit
#https://overthewire.org/wargames/bandit/

#requires sshpass
#sudo apt-get install sshpass

#Prompt for the username and password
read -p "enter the level: " level
password_list=(
	"bandit0"				# level 0
	"ZjLjTmM6FvvyRnrb2rfNWOZOTa6ip5If"	# level 1
	"263JGJPfgU6LtdEvgfWU1XP5yac29mFx"	# level 2
	"MNk8KNH3Usiio41PRUEoDFPqfxLPlSmx"	# level 3
	"2WmrDFRmJIq3IPxneAaMGhap0pFhF3NJ"	# level 4
	"4oQYVPkxZOOEOO5pTW81FB8j8lxXGUQw"	# level 5
	"HWasnPhtq9AVKe0dmk45nxy20cvUa6EG"	# level 6
	"morbNTDkSW6jIlUc0ymOdMaLnOlFVAaj"	# level 7
	"dfwvzFQi4mU0wfNbFOe9RoWskMLg7eEc"	# level 8
	"4CKMh1JI91bUIZZPXDqGanal4xvAg0JM"	# level 9
)
echo

#echo "bandit$level"
#echo "The password for level $level is: ${password_list[$level]}"
#sshpass -p "bandit$level" ssh "$username"@bandit.labs.overthewire.org -p 2220

sshpass -p ${password_list[$level]} ssh "bandit$level"@bandit.labs.overthewire.org -p 2220