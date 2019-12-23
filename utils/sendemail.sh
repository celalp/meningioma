 
#! /bin/bash

# this takes many arguments
# $1 temporary password
# $2 admin email
# $3 user email
# $4 admin username
# $5 admin password
# $6 whether password reset or new account string "signup","reset"

if [ $6 = "signup" ]
then
cat > mailfile << EOL
Thank you for sigining up for our app. 

Your temprorary password is $1. Please activate your account by using this password and
setting up a new one. 

If you did not create this account please contact us immediately at $2
EOL
elif [ $6 = "reset" ]
then
cat > mailfile << EOL
You have requested to reset your password. 

Your temprorary password is $1. Once you log in you will be prompted to reset your password. 

If you did not create this account please contact us immediately at $2
EOL
fi

cat mailfile | sendemail -f $2 \
 						 -t $3 \
 						 -xu $4 \
 					   -xp $5 \
 					   -o tls=yes \
 					   -s smtp.gmail.com:587 
 					     

rm mailfile
