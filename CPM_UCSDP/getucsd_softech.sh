#!/bin/sh

get() {
	echo ":: Getting $2 ::"
	mkdir -p $1
	cd $1
	curl -o $2 $3
	cd ../..
}

get_softech_floppy() {
	get softech/floppy $1.IMD http://www.bitsavers.org/bits/UCSD_Pascal/softech/floppy/$1.IMD
}

get_softech_dist() {
	get softech/dist $1.IMD http://www.bitsavers.org/bits/UCSD_Pascal/softech/dist/$1.IMD
}

#Dist
get_softech_dist CPM40DB
get_softech_dist CZP40DC
get_softech_dist HZP40DB
get_softech_dist OII40D
get_softech_dist SCP40D
get_softech_dist UZP40DC


#Floppy
get_softech_floppy 88SYS
get_softech_floppy 88SYS_CPY2
get_softech_floppy CPM_BOOTER
get_softech_floppy INTCPM
get_softech_floppy INTZ80
get_softech_floppy STARTUP
get_softech_floppy SYS1
get_softech_floppy SYS3
get_softech_floppy SYSCPM1
get_softech_floppy UTIL1
