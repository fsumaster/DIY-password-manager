#!/bin/bash

# Declare variables
lowercase="abcdefghijklmnopqrstuvwxyz"
uppercase="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
numbers="0123456789"
special="!@#$%^&*()-_+={}[]\|:;\"'<>,.?/'"

# Function to generate a new password
generate_password() {
  # Initialize an empty phrase
  phrase=""

  # Loop 15 times to create the phrase
  for i in {1..15}; do
    # Choose a random character set
    case $((RANDOM % 4)) in
      0) char_set=$lowercase;;
      1) char_set=$uppercase;;
      2) char_set=$numbers;;
      3) char_set=$special;;
    esac

    # Add a random character from the chosen set to the phrase
    len=${#char_set}
    random_index=$((RANDOM % len))
    phrase="$phrase${char_set:random_index:1}"
  done
  
  # Prompt the user for a reference name example:gmail
  read -p "Create a reference name for this set of credentials: " reference

  # Prompt the user for an email or username
  read -p "Enter email or username: " email_username

  # Display to the user the generated information
  echo "#HERE IS YOUR INFO: [$reference] - $email_username : $phrase"
  
  # Append the reference/email/username and generated password to a file
  echo "[$reference] - $email_username : $phrase" >> manager.txt
  
  # Encrypt the file with gpg using a user-provided passphrase
  read -s -p "Enter passphrase to encrypt the file: " passphrase
  echo
  gpg -c --cipher-algo AES256 --passphrase "$passphrase" manager.txt
  
  echo "File encrypted"
  rm manager.txt
}

# Function to decrypt the file and open in gedit
decrypt_password() {
  read -s -p "Enter passphrase to decrypt the file: " passphrase
  echo
  if gpg -d --passphrase "$passphrase" manager.txt.gpg > manager.txt 2>/dev/null; then
    echo "File decrypted"
    if command -v gedit &> /dev/null; then
      gedit manager.txt &
      wait $!
      echo "Encrypting file..."
      gpg -c --cipher-algo AES256 --passphrase "$passphrase" manager.txt
      echo "File encrypted"
      rm manager.txt
    else
      echo "gedit is not installed. Please install gedit or modify the script to use another text editor."
    fi
  else
    echo "Incorrect passphrase"
  fi
}

# Function to listen for changes in the file and trigger encryption
listen_for_changes() {
  echo "Listening for changes in the file..."
  inotifywait -m -e modify manager.txt | while read path action file; do
    echo "File modified. Encrypting..."
    gpg -c --cipher-algo AES256 --passphrase "$passphrase" manager.txt
    echo "File encrypted"
  done
}

#Menu
while true; do
  echo "#######################################"
  echo "# Password Generation/Decryption tool #"
  echo "# Menu:                               #"
  echo "# 1. Generate new password            #"
  echo "# 2. Decrypt password                 #"
  echo "# 3. Listen for changes in file       #"
  echo "# 4. Exit                             #"
  echo "#######################################"
  read choice
  case $choice in
    1) generate_password;;
    2) decrypt_password;;
    3) listen_for_changes;;
    4) exit;;
    *) echo "Invalid choice";;
  esac
done
