#!/bin/bash


mkdir ./VideoCreations &> /dev/null


listcreations() {

            echo "Creations:  "
            echo

            LIST=`ls ./VideoCreations`
            LIST=${LIST//.???/}    # removes file extension       
            if (( `echo "${LIST// /}" | wc -w` == "0" ));
            then
                echo "No existing creations stored"
                return 1
            fi
            printf "${LIST// /.\\n}\n" | sort &> ./temp/list
            cat -n ./temp/list
            echo

}


while true ; do
    echo "========================================================"
    echo "Welcome to the Wiki-Speak Authoring Tool"
    echo "========================================================"
    echo "Please Select from one of the following options:"
    echo 
    echo "   (l)ist existing creations"
    echo "   (p)lay an existing creations"
    echo "   (d)elete an existing creation"
    echo "   (c)reate a new creation"
    echo "   (q)uit authoring tool"
    echo
    echo -n "Enter a selection [l/p/d/c/q]:     "
    read input
    echo
    
	mkdir ./temp &> /dev/null
    
case $input in 

        
        [lL]*) #list creations
            listcreations
            read -p "Press enter to continue..."
        ;;
    
        [pP]*) # select a creation to play
            
            listcreations
            EXIST=$?

            while [ $EXIST -eq 0 ]  ; do
            echo 
            read -p "Select the index of the file you want to play:    " PLAY
            COUNT=`cat ./temp/list | wc -l`
                if (( 1<=$PLAY && $PLAY<=$COUNT))
                then
                    VIDEO=`sed -n ${PLAY}p ./temp/list` 
                    ffplay -autoexit ./VideoCreations/$VIDEO.mp4 &> /dev/null
                    echo

                    break
                else
                    echo "ERROR: select an number from the list"
                fi
            
                
            
            done
            
    
        ;;
    
        [dD]*) # delete a creation
            
            listcreations
            EXIST=$?
            
            while [ $EXIST -eq 0 ]; do
            echo 
            read -p "Select the index of the file you want to delete:    " DELETE
            COUNT=`cat ./temp/list | wc -l`
                if (( 1<=$DELETE && $DELETE<=$COUNT))
                then
                
                    VIDEO=`sed -n ${DELETE}p ./temp/list` 
                    
                    read -p "Are you sure you want to delete "$VIDEO"?   " REPLY
            
                    case $REPLY in
                    
                        [yY]*)
                        VIDEO=`sed -n ${DELETE}p ./temp/list` 
                
                        rm -f ./VideoCreations/$VIDEO.mp4
                        echo "Creation Successfully Deleted"
                        ;;
                        
                    esac
                    
                    read -p "Press enter to continue...  "
                    break
                    
                else
                    echo "ERROR: select an number from the list"
                fi
            
            done
            
    
        ;;
    
        [cC]*)
        
            while true; do
            
                read -p "What term would you like to search on WIKIPEDIA?   " TERM
                echo "searching ..."
                
                    wikit ${TERM// /}  &> ./temp/${TERM// /} 
                    
                    TEXT=`head --lines=1 ./temp/${TERM// /}`
                    if [ "$TEXT" == "${TERM// /} not found :^(" ]
                    then
                    
                        echo "Error Term not found"
                        ACTION="x"
                        while [ "$ACTION" != "r" ] && [ "$ACTION" != "q" ]
                        do 
                        
                        read -p "Would you like to (r)etry or (q)uit?   " ACTION                            
                        done
                        
                        
                        if [ "$ACTION" == "r" ]
                        then
                                continue
                        elif [ "$ACTION" == "q" ]
                        then
                                break
                        fi
                    fi
                    printf "${TEXT//. /.\\n}\n" 1> ./temp/${TERM// /} 2> /dev/null
                    
                    COUNT=`cat ./temp/${TERM// /} | wc -l`
                    
                    cat -n ./temp/${TERM// /}
                    
                    while true ; do
                        echo
                        read -p "how many lines do you want in your Creation?   "   LINES
                        echo
                        
                        
                        if (( 1<=$LINES && $LINES<=$COUNT))
                        then
                            
                            # takes the specified number of lines and converts ot text to speech
                            head --lines=$LINES ./temp/${TERM// /} | text2wave -o ./temp/temptts.wav
                            LENGTH=`soxi -D ./temp/temptts.wav`

                            break            
                        else
                        
                            echo "Please enter a valid number"
                            continue
                        fi
                       
                    done
                    
                    echo
                    read -p "What would you like to name your creation?   " FILE
                    echo
                   
                   
                   
                   
                    
                    if [ -f "./VideoCreations/${FILE// /"_"}.mp4" ]
                    then
                        ACTION="x"
                        while [ "$ACTION" != "o" ] && [ "$ACTION" != "r" ]
                        do 
                            read -p "${FILE// /"_"} already exists, would you like to (o)verwrite or (r)ename? " ACTION
    
                            if [ "$ACTION" == "o" ]
                            then
                                rm -f "./VideoCreations/${FILE// /"_"}.mp4"
                            elif [ "$ACTION" == "r" ]
                            then
        
                                FILE=""
                                while [ -e "./VideoCreations/${FILE// /_}.mp4" ] || [ -z "${FILE// /"_"}" ]
                                do
                                read -p "File exists, what do you want to rename to? " FILE
                                done 
                
                            fi
                        done
                    fi
      
      
                    # converts wav to mp3
                    ffmpeg -i ./temp/temptts.wav -vn -ar 44100 -ac 2 -b:a 192k ./temp/temptts.mp3 &> /dev/null

                    # creates video with word and background
                    ffmpeg -f lavfi -i color=c=blue:s=320x240:d=$LENGTH -vf "drawtext=fontfile=/path/to/font.ttf:fontsize=30: fontcolor=white:x=(w-text_w)/2:y=(h-text_h)/2:text='$TERM'" ./temp/${FILE// /"_"}.mp4 &> /dev/null

                    #merge video and mp3 files
                    ffmpeg -i ./temp/${FILE// /"_"}.mp4 -i ./temp/temptts.mp3 -c:v copy -c:a aac -strict experimental ./VideoCreations/${FILE// /"_"}.mp4  &> /dev/null


                    echo "Successfully created a creation named ${FILE// /"_"}"
                    echo
                    read -p "Press enter to continue..."
                 break
       
            done
        ;;
    
        [qQ]*)
    
            break
        ;;
        
        *)
            echo "please type in a valid input !!!"
            echo 
        
        ;;
        
    esac
    rm -r ./temp &> /dev/null
done

rm -r ./temp &> /dev/null
