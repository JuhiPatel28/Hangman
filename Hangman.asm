.data
#Variables
Word: .word 0

#Msgs
Hello: .asciiz "Hello!\n"
Playerprompt: .asciiz "Please enter {1} for one player or {2} for two players: "
Wordprompt: .asciiz "Please enter one word (alphabetical characters only): "
Repeat: .asciiz "You have already guessed this letter.\n"
Guessprompt: .asciiz "\nPlease guess a letter: "
InvalidLetter: .asciiz "\nInvalid input. Please enter an alphabetical letter."
InvalidNumber: .asciiz "Invalid input. Please enter 1 or 2.\n"
Already: .asciiz "Already guessed: "
made2: .asciiz "Made2\n"
Bye: .asciiz "\nBye!"
newline: .asciiz "\n"

#Arrays
AllGuess: .space 30 
RightGuess: .space 30

.text
main:	
	la $a0, Hello
	jal printstring	
	la, $a0, Playerprompt
	jal printstring
	
whileplayer:
	li $v0, 5
	syscall
	beq $v0, 1, oneplayer
	beq $v0, 2, twoplayer
	la, $a0, InvalidNumber
	jal printstring
	la, $a0, Playerprompt
	jal printstring
	j whileplayer
	
oneplayer: 
	la $a0, Wordprompt
	jal printstring
	li $v0, 8
	la $a0, Word
	la $a1, 100
	syscall
	j prehangman
	
twoplayer: 
	la $a0, made2
	jal printstring
	j prehangman
	
prehangman:
	li $s5, 0 #number of turns
	li $s6, 0 #number of right guesses

	#load arrays into registers
	la $a0, RightGuess 
	la $a1, AllGuess
	la $a2, Word
	
	jal underscore
	jal printstring
	jal hangman
	j exit
	
hangman: 
	jal getcharacter
	move $a3, $s2 #store guessed character into a3

	la $a1, AllGuess #re-load guesses into register
	la $a2, Word #re-load word into register
			
					
###################################################
#Getting user to guess a letter + input validation#
###################################################
getcharacter: 
	addi $sp, $sp, -12 #Add 3 bytes to stack
	sw $ra, 0($sp) #Save original return address
	sw $a0, 4($sp) #Save original rightly-guessed-letters array
	sw $s0, 8($sp) #Save original s0 register
		
	la $a0, Guessprompt
	li $v0, 4
	syscall
	li $v0, 12 #get char input
	syscall
	move $s2, $v0 #store inputted letter in s2
	
	bgt $s2, '`', lowercasealready #if the character entered is already lowercase
	addi $s2, $s2, 32 #convert character to lowercase
	
lowercasealready:
	bgt $s2, 'z', notcharacter #if the character is greater than z, go to notcharacter
	blt $s2, 'a', notcharacter #if the character is less than a, go to notcharacter
	
	lw $s0, 8($sp) #Get original s0 register
	lw $a0, 4($sp) #Get original rightly-guessed-letters array
	lw $ra, 0($sp) #Get original register address
	addi $sp, $sp, 12 #Subtract 3 bytes from stack
	
	jr $ra #call return
	
notcharacter:
	la $a0, InvalidLetter #print invalid letterv
	li $v0, 4
	syscall
	j getcharacter #loop again
	
#####################################################
#Updating and checking character-array for duplicate#
#####################################################
addguess: 
	addi $sp, $sp, -8 #Add 3 bytes to stack
	sw $a1, 0($sp) #Save original guessed-letters array
	sw $a2, 4($sp) #Save original word

addguessloop:
	lb $t2, 0($a2) #Load the first letter of the word
	
	
########################################
#Getting the underscore letters display#
########################################
underscore:
	addi $sp, $sp, -12 #Add 3 bytes to stack
	sw $a2, 0($sp) #Save original word
	sw $a0, 4($sp) #Save original rightly-guessed-letters array
	sw $a1, 8($sp) #Save original guessed-letters array
	
	li $v0, 0 	
	move $t1, $a1 #Store beginning of guessed-letters array
	addi $t5, $t5, 0
	li $t6, ' ' #load space for display
	li $t7, '_' #load underscore for display	
	
underscoreloop:
	lb $t2, 0($a2) #load first letter of word
	lb $t3, 0($a1) #load first letter of guessed-letters array
	beq $t3, $t2, displayletter #if the guess is correct, go to displayletter
	beq $t3, $zero, finalunderscoreloop #if it is the end of the array, go to finalunderscoreloop
	addi $t5, $t5, 1
	
continueunderscopeloop: #if the letters dont match and it is not the end of the array, go to continueunderscoreloop
	sb $t7, 0($a0) #store whatever is in $t7 in rightly-guessed-letters array
	addi $a1, $a1, 1 #increment guessed-letters array by 1
	j underscoreloop #loop until one of the branch conditions is met
	
finalunderscoreloop:
	move $a1, $t1 #return to first element of the guessed-letters array
	
	addi $a2, $a2, 1 #go to the next letter in the original word
	lb $t2, 0($a2) #load letter of word at current index
	beq $t2, $zero, endunderscoreloop
	
	beq $t5, $zero, emptyguess #if the guessed-letter array is totally empty, go to emptyguess
	
	sb $t6, 0($a0) #store ' ' in rightly-guessed-letters array (for clarity in viewing)
	addi $a0, $a0, 1 #go to the next element of the rightly-guessed-letters array
	li $t7, '_' #reload underscore for display (it may have changed)
	
	j underscoreloop

endunderscoreloop:
	lw $a1, 8($sp) #Get original guessed-letters array
	lw $a0, 4($sp) #Get original rightly-guessed-letters array
	lw $a2, 0($sp) #Get original word
	addi $sp, $sp, 12 #Subtract 3 bytes from stack
	
	jr $ra #call return

displayletter:
	move $t7, $t2 #load the letter of the word into $t7
	j continueunderscopeloop
	
emptyguess: #if it is the first iteration of the program, print only the underscores
	sb $t7, 0($a0) #store '_' in rightly-guessed-letters array 
	addi $a0, $a0, 1 #go to the next element of the rightly-guessed-letters array
	sb $t6, 0($a0) #store ' ' in rightly-guessed-letters array (for clarity in viewing)
	addi $a0, $a0, 1 #go to the next element of the rightly-guessed-letters array
	j underscoreloop
	

###################	
#printing funtions#	
###################			
printstring: 
	li $v0, 4
	syscall
	jr $ra
	
exit: 
	la $a0, Bye
	jal printstring
	li $v0, 10 # terminate program run and
   	syscall #Exit    
	
