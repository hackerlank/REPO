#!/bin/sh

#       Name:    CreateRepoList.sh
#       Version: 2
#       License:  GPL v3
#       https://gnu.org/licenses/gpl.html





# script use:
# curl , rpm , lynx , awk


# This script can download packages from repository 
# script tested on english language.
#



#---Checking exist dirs to work --{
aaaa=`pwd`/TMP/
aaab=`pwd`/RepoArchive/
if [ ! -d $aaaa ];
   then
   echo "TMP dir not found / will created."
   mkdir TMP
fi
if [ ! -d $aaab ];
   then
   echo "RepoArchive dir not found / will created."
   mkdir RepoArchive
fi
#---------------------------------}





# ---- Warning --- {
aaa=$(uname -a)
if echo $aaa | grep -q "i686"
then
	echo "----                    -----"
	echo " Warnig ! "
	echo " You have 32bit system, script is for 64bit system"
	echo " The end. "
	echo "----                    -----"
	exit
fi
# ---- Warning --- }






#---------Check date when script last run ------------ {
#  If file exist
function check_date
{
if [ -f `pwd`/TMP/date.log ]
	then
       # ab = check how old is file
       ab=$( ls --full-time  `pwd`/TMP/date.log | cut -d " " -f6 )
    #  ab= 2015-03-05

    else
	  echo -e " \t \t RepoArchive can be old now, write: \napt2 --update \n \t \t to update RepoArchive \n "
      ab="1000-10-10"

fi


#  echo $ab
#    debug help


# Check date now.
ac=$( date +"%Y-%m-%d" )
# ac= 2015-03-05
}

# funkcion above
check_date

#---------Check date when script last run ------------ }





# debug:
# echo " 0- $0 , 1- $1 ,2- $2 ,3- $3 "
VERBOSE=0


   case $1 in
       --debug)
       VERBOSE=1
		echo "Sorry debug option not exist for now.  "
       ;;
		--search)
		VERBOSE=2
		echo "Searching..."
		;;
		--update)
		VERBOSE=3
		LimitRate="$2"
		limit="$3"
		;;
		--force-update)
		VERBOSE=4
		LimitRate="$2"
		limit="$3"
		;;
		--remove)
		VERBOSE=5
		;;
		--clear)
		VERBOSE=6
		;;
       --help)
		echo "----------------------------------------------------------------------------"
		echo "usage: $0 --update --force-update --limit-rate 2M --search word "
		echo "----------------------------------------------------------------------------"
		echo " --update:       create / update repo archive (this can create one for day) "
		echo "                 this option is recommended before --search file"
		echo " --force-update: force update / create repo archive now "
		echo " --limit-rate:   (--update-force --limit-rate) reduces download to limit rate,"
		echo "                 you can use in G , M , K , B rate, example (--limit-rate 500G)"
		echo " --search:       looking word from repolist"
		echo " --help:         show options"
		echo " --clear:        clear window terminal/konsole."
		echo " --remove:       check which packages are not used and remove from /RepoArchive/"
#		echo " --renice:       renice can change priority this script, from -20 to 19
#		-20 Is the highest priority and 19 the lowest. "
# renice -n 19 -p $$ "
       exit
       ;;
       *)
       # unknown option
       echo "Error: unknown option"
       echo "usage: $0 --help"
       exit
       ;;
   esac















#  ---------- Engine to create RepoList  ---------- {
function create_repo
{




# This loop comparison of file modification date.
if [ $ab != $ac ]
	then
    echo "File date.log is old and will created new"
	
	# remove all files from TMP folder
	rm -f `pwd`/TMP/*



#--------   Download list from " 64 bit" ------------------{
 echo " Download list from 64 bit repo. "

lynx  -dump -listonly  http://ftp.nluug.nl/pub/os/Linux/distr/pclinuxos/pclinuxos/apt/pclinuxos/64bit/RPMS.kde/ | cut -d "/" -f14 | grep "rpm" > `pwd`/TMP/kde.list

echo "From RPMS.kde ready."

lynx  -dump -listonly  http://ftp.nluug.nl/pub/os/Linux/distr/pclinuxos/pclinuxos/apt/pclinuxos/64bit/RPMS.retro/ | cut -d "/" -f14 | grep "rpm" > `pwd`/TMP/retro.list

echo "From RPMS.retro ready."

lynx  -dump -listonly  http://ftp.nluug.nl/pub/os/Linux/distr/pclinuxos/pclinuxos/apt/pclinuxos/64bit/RPMS.x86_64/ | cut -d "/" -f14 | grep "rpm" > `pwd`/TMP/x86_64.list

echo "From RPMS.x86_64 ready."

lynx  -dump -listonly  http://ftp.nluug.nl/pub/os/Linux/distr/pclinuxos/pclinuxos/apt/pclinuxos/64bit/RPMS.xfce4/ | cut -d "/" -f14 | grep "rpm" > `pwd`/TMP/xfce4.list

echo "From RPMS.xfce4 ready."
echo "Download finished"

#echo "date" > `pwd`/TMP/date.log
touch `pwd`/TMP/date.log







echo " --loop -------------------"

# loop - for files *.list (sections)
for file in TMP/*.list
do  
	ada=$(echo $file  | cut -d "/" -f2)
	echo $ada


	# In $file  is $ad lines.
	ad=$(cat -n $file | tail -1 | awk '{print $1}')
	echo "    $ad packages in this section $ada "


    #   ---------------------------------{
	# if directory not exist create it
	if [ ! -d `pwd`/RepoArchive/$ada ]
	then
		mkdir `pwd`/RepoArchive/$ada
	fi
    #   ---------------------------------}


	# loop - for number lines in file *.list
	for i in `seq 1 $ad`
	do
		ae=$(awk 'NR=='$i $file)
		# ae=line from file


		# sphinx-2.0.10-1pclos2014.x86_64.rpm    :   10042/11074  x86_64.list
		echo " $ae    :    $i/$ad  $ada "


			# if file not exist
			if [ ! -f `pwd`/RepoArchive/$ada/$ae ]
			then
				
				# af=xfwm4-themes-doc-4.10.0  (without ... noarch.rpm)
				af=$( echo $ae | rev | cut -d"-" -f 2- | rev )


				echo "Package exist in system: $af"
                # check if package exist in system
				ag=$(rpm -q $af)

				# if "is not installed" exist in output
				if echo $ag | grep -q "is not installed"
				then
					echo "Download needed $ag "
					echo $ada
					echo $file
					echo $ae
					echo "---------------"
					
					ah=$(echo $ada | cut -d "." -f1)



					#-----------------------------------------{
					#  --limit-rate for curl, $LimitRate and $limit are from "case" menu -> --update , --force-update
					aha="500G"
					if echo $LimitRate | grep -q "limit-rate"
					then
						aha="$limit"
					fi
					echo " ----------- limit-rate =   $aha   ------------"
					#-----------------------------------------}




#					cd `pwd`/TMP/
					curl --limit-rate $aha -O http://ftp.nluug.nl/pub/os/Linux/distr/pclinuxos/pclinuxos/apt/pclinuxos/64bit/RPMS.$ah/$ae
					rpm -qpl $ae > `pwd`/RepoArchive/$ada/$ae
                    rm $ae
					echo "Downloaded rpm..., readed, removed."




                else
					rpm -ql $af > `pwd`/RepoArchive/$ada/$ae
				fi


				


			fi
	done

done




echo "----------"

else
	echo "CreateRepoList was updated today. (Can be updated one per day)"
	echo -e " \t If you want refresh list now, try \n--force-update \n \t or delete date.log file."
fi


}

if [ $VERBOSE -eq 3 ]
then 
	create_repo
fi
#  ---------- Engine to create RepoList  ---------- }








#  ---------- Update Force  ------------------------ {
if [ $VERBOSE -eq 4 ]
then 
	rm  `pwd`/TMP/date.log

	# function
	check_date
	# function
	create_repo
fi
#  ---------- Update Force  ------------------------ }







#  ---------- Engine to search word  ---------- {
if [ $VERBOSE -eq 2 ]
then 





grep -RIlm 1 "$2" RepoArchive/ > `pwd`/TMP/search.log
	# In $file  is $ad lines.
	baa=$(cat -n `pwd`/TMP/search.log | tail -1 | awk '{print $1}')


		# if $baa is empty
		if [ -z $baa ] 
			then 
			echo "  Path: $bb  "
			echo " Not Founded $2."
			exit
		else 
			echo " Founded in  $baa packages. "
		fi

# search result
for i in `seq 1 $baa`
do

		bb=$(awk 'NR=='$i `pwd`/TMP/search.log)
        # echo $bb
        # line from ba


		echo "-------------------------------"
		echo "  Path: $bb  "

		# This lines which contains searched "word".
		bc=$(cat $bb | grep "$2")
		echo "$bc"
		echo "-------------------------------"


done

fi
#  ---------- Engine to search word  ---------- }








#  ---------- Remove  ---------- {
if [ $VERBOSE -eq 5 ]
then



	echo -e " \n Write: "
	echo " 1 -if you want remove this all old packages from RepoArchive."
	echo " 2 -if you want remove only packages which not exist in system."
	echo " 3 -Cancel "

	read input
   case $input in
		1)
		VERBOSE=1
       ;;
		2)
		VERBOSE=2
		;;
		3)
		exit
       ;;
       *)
       # unknown option
       echo "Unknown option and exit."
       exit
       ;;
   esac

#--------------------------------------
function create_remove
{
	# cleaning old /TMP/*.create_remove
	rm -vf `pwd`/TMP/*.remove



	for file in RepoArchive/*.list
	do
		# ca=section
		ca=$(echo $file | cut -d "/" -f2)

#			echo $ca

		# save list packages to file
		ls RepoArchive/$ca | sort > `pwd`/TMP/$ca.Archive
		echo "-----------------------------"


#			cat `pwd`/TMP/$ca.Archive


		# merge list RepoArchive with repository list = packages which
		# diff 2 files | only with "<" | cut "< "    save to file
		diff `pwd`/TMP/$ca.Archive `pwd`/TMP/$ca | grep "<" | cut -d " " -f2 > `pwd`/TMP/$ca.remove

	done
}
#--------------------------------------





#--------------------------------------
function create_not_installed_in_system
{

	# cleaning old /TMP/*.not_installed_removed
	rm -vf `pwd`/TMP/*not_installed_removed
#	rm -v removing_2.log


	for file in TMP/*.list.remove
	do
		# ca=file (kde.list.remove)
		ca=$(echo $file | cut -d "/" -f2)

			# debug
#			echo -e " \n \n $ca ca --/ create_not_installed_in_system"


		# If exist something in file *.list.remove
		if [ -s "TMP/$ca" ]
		then



			# In file *.remove is $aa lines.
			cb=$(cat -n `pwd`/TMP/$ca | tail -1 | awk '{print $1}')

				# debug
				echo -e "In file $ca is  $cb lines ( $cb cb lines --/ create_not_installed_in_system) \n \n"




			# for i in every line "*.list.remove"
			for i in `seq 1 $cb`
			do

					# debug
#					 echo "Loop nr: $i"

      			 # line from *.list.remove , line from kde.list.remove (calligra-2.9.2-1pclos2015.x86_64.rpm)
      			 cc=$(awk 'NR=='$i `pwd`/TMP/$ca)


					# debug
#					echo "$cc cc /-- line from $ca --/ create_not_installed_in_system"


				# part name package (calligra)
				cd=$( echo $cc | rev | cut -d"-" -f 3- | rev )

					# debug
#					echo "$cd cd ---- / create_not_installed_in_system"



				# if in " rpm -q package " exist spacebar ("package thunar-doc is not installed" this sentence have spacebar)
				# then package not installed
  			    if rpm -q $cd | grep -q " "
				then
					# cc=(calligra-braindump-2.9.2-1pclos2015.x86_64.rpm)
					# cd=(calligra-braindump)
					echo " --  $cd  - (cd) -- Not installed in system --------(create_not_installed_in_system)"

					# cda=(kde.list)
					cda=$(echo $ca | cut -d "." -f-2)
	
					# save list to log
					echo "$cc" >> `pwd`/TMP/$cda.not_installed_removed

				#-- Remove 2 --------
						echo "Removing... "

							# debug
#							echo `pwd`/RepoArchive/$cda/$cc >> removing_2.log

	
						rm -v `pwd`/RepoArchive/$cda/$cc
				#-- Remove 2 ---------

				else
					echo " -- $cd (cd) This is installed. (create_not_installed_in_system) "
				fi

			done

		# Nothing exist in file *.list.remove
		else
			echo 'Nothing to remove.'
		fi

	done
}
#--------------------------------------

#--------------------------------------
function remove_packages_from_list
{
			# cleaning old files
#			rm -v removing_1.log

			# debug
			# $daa=path ("TMP/*.list.remove")

				# debug
#				echo "$daa - (daa) --/ remove_packages_from_list"



	# for every (*.list.remove)
	for file in $daa
	do

		# If exist something in file *.list.remove
		if [ -s "TMP/$daa" ]
		then

			# da=files  (kde.list.remove)
			da=$(echo $file | cut -d "/" -f2)

				#debug
#				echo -e " ------ \n \n $da -- da \n "
		

			# dc= lines in file (4)
			dc=$(cat -n `pwd`/TMP/$da | tail -1 | awk '{print $1}')

				# debug
#				echo "$dc - dc --/ remove_packages_from_list"


			# section (kde.list)
			dca=$(echo $da | cut -d "." -f-2)
			
				# debug
#				echo "$dca - dca --/ remove_packages_from_list"



				# for i in every line
				for i in `seq 1 $dc`
				do
      				 #line from kde.list.remove (calligra-2.9.2-1pclos2015.x86_64.rpm)
      				 dd=$(awk 'NR=='$i `pwd`/TMP/$da)
	
						#debug
						echo "$dd - dd --/ remove_packages_from_list"
#						echo "$dd   /   $da"
			

				#-- Remove 1 --------
					echo "Removing... "
	
						# debug
#					echo `pwd`/RepoArchive/$dca/$dd >> removing_1.log

					rm -v `pwd`/RepoArchive/$dca/$dd
				#-- Remove 1 ---------

			
				done

		# Nothing exist in file *.list.remove
		else
			echo 'Nothing to remove.'
		fi


	done
}
#--------------------------------------



#---------------------------------------------------------------------{
# Start Remove

	# function to update RepoArchive
	create_repo
	echo "---------------  create_repo -the end  --------------------"

	# function which create "*list.remove", contains packages(with version) 
	# which not exist in repository but exist in RepoArchive.
	create_remove
	echo "---------------  create_remove -the end  -------------------"


	# clear terminal
#	printf "\ec"


	df=$(ls TMP/*.list.remove)
	if echo $df | grep -q "list.remove"
	then
			echo -e "-------------*.list.remove files ready to remove packages.------------------- \n \n "


		#--------------------------------------------------------------
			if [ $VERBOSE -eq 1 ]
			then
				# path to file from which will be removed packages
				daa="TMP/*.list.remove"

				# function which create files "*.not_installed", contains packages(with version)
				# which are not installed in system, but exist in "*.list.remove".
				remove_packages_from_list
				echo -e "--------------- VERBOSE -eq 1 -the end  ------------------- \n"

#			else
#				echo "Nothing to remove -*.list.remove files not exist"
			fi
		#--------------------------------------------------------------


		#--------------------------------------------------------------
			if [ $VERBOSE -eq 2 ]
			then 
				echo -e "--------------- VERBOSE -eq 2 -START  ------------------- \n"				

				# function
				echo "--------------- create_not_installed_in_system - begin  -------------------"
				# This function create files which contains packages not installed in system
				# from files "TMP/*.list.remove" to "TMP/*.not_installed_in_system"
				create_not_installed_in_system
				echo "--------------- create_not_installed_in_system -the end  -------------------"


			echo "--------------- VERBOSE -eq 2 - THE END  -------------------"
			fi
		#--------------------------------------------------------------


	else
		echo "*.list.remove files not exist, so nothing to remove"
	fi

	echo -e " \n Done \n "
#---------------------------------------------------------------------}
# End Redmove

fi
#  ---------- Remove  ---------- }













#  ---------- Clear  ---------- {
if [ $VERBOSE -eq 6 ]
then
	printf "\ec"
	# this clean terminal 
fi

#  ---------- Clear  ---------- }



