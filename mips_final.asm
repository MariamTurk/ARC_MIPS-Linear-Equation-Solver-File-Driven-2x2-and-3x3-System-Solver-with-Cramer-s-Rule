.data
# Common format strings and labels for output
newline_str:     .asciiz "\n"                        # Newline for output separation
space_str:       .asciiz " "                         # Space for formatting output
prompt_continue: .asciiz "Would you like to solve another system? (Y/n): "
input_buffer:    .space 500                          # Buffer for holding each line from the input file
output_buffer:   .space 128
temp_buffer:     .space 12

# Buffers and labels for user prompts and inputs
prompt_file_input:    .asciiz "Enter input file name: " # Prompt for input file name
input_filename:       .space 64                       # Buffer for storing input file name
prompt_output_choice: .asciiz "Choose output (f/F for file, s/S for screen): " # Output choice prompt
output_choice_flag:   .space 2                         # Buffer to store the output choice flag
error_invalid_choice: .asciiz "Error: Invalid choice, exiting program.\n"
output_filename_prompt: .asciiz "Enter output file name: "
output_filename:      .space 64                       # Buffer for storing output file name

# Error messages for common issues
error_file_read:      .asciiz "Error: Could not read file.\n"
error_div_zero:       .asciiz "Error: Division by zero encountered!\n"
error_format:         .asciiz "Error: Invalid format encountered in equation.\n" # Error for format issues

# Equation formatting labels
label_x:         .asciiz "X"
label_y:         .asciiz "Y"
label_z:         .asciiz "Z"
label_system:    .asciiz "System "
label_result:    .asciiz "Equation: "
operator_plus:   .asciiz "+"
operator_minus:  .asciiz "-"
operator_equals: .asciiz " = "
operator_divide: .asciiz "/"
x_read:	     .byte 0
y_read:          .byte 0
z_read:          .byte 0
equals_read:     .byte 0
# Buffers for integer-to-string conversion and display formatting
int_conv_buffer: .space 16                            # Buffer for integer-to-ASCII conversion
int_result_temp: .space 4                             # Temporary buffer for intermediate results

# Coefficient arrays and result storage for parsed equations
coeff_array_x:   .space 30                            # Array to hold coefficients for 'x' in multiple systems
coeff_array_y:   .space 30                            # Array to hold coefficients for 'y' in multiple systems
coeff_array_z:   .space 30                            # Array to hold coefficients for 'z' in multiple systems
results_array:   .space 30                            # Array to store the right-hand side results of equations
system_type_array: .space 30                          # Array to indicate if equation is 2 or 3 variable system

# Variables for tracking systems and results
system_counter:     .byte 0                           # Counter for the number of systems processed
input_choice_flag:  .space 2                          # Flag for tracking user's choice (file or screen)
input_file_flag:    .space 2		      # Flag for tracking if user inputted a file or not

# Error messages and prompts for enhanced feedback
error_general:       .asciiz "Error: Invalid operation or file error encountered.\n"
confirm_exit_prompt: .asciiz "Are you sure you want to exit? (Y/n): "
read_file_first:     .asciiz "Please read an input file first.\n"

# User Menu Prompt
menu_prompt:    .asciiz "Choose an option:\n1 - Read input file\n2 - f or F for output to file\n3 - s or S for screen output\n4 - e or E to exit\nChoice: "
menu_choice:    .space 2                             # Buffer to store menu choice input

det_a:	    .word 0
det_a1:	    .word 0
det_a2:	    .word 0
det_a3:         .word 0

.text
.globl main

.macro MOVE_MEM $src, $dest
    sb $src, 0($dest)
    addiu $dest, $dest, 1
.end_macro

.macro PRINT_VAR_RES $src, $dest
    MOVE_MEM $src, $dest
    li $src, ' '
    MOVE_MEM $src, $dest
    li $src, '='
    MOVE_MEM $src, $dest
    li $src, ' '
    MOVE_MEM $src, $dest
.end_macro

main:
    # Display the main menu and handle user input
display_menu:
    # Print the menu prompt
    li $v0, 4                                 # Syscall for print string
    la $a0, menu_prompt                       # Load address of the menu prompt
    syscall

    # Read menu choice from user
    li $v0, 8                                 # Syscall for reading a string
    la $a0, menu_choice                       # Buffer to store the user's menu choice
    li $a1, 2                                 # Limit the input to 1 character
    syscall
    
    la $a0, newline_str
    li $v0, 4
    syscall
    
    # Process the user menu choice
    lb $t0, menu_choice                       # Load the user's choice into $t0
    li $t1, '1'                               # ASCII code for '1'
    beq $t0, $t1, handle_read_input           # If choice is '1', go to file reading section

    li $t1, '2'                               # ASCII code for '2'
    beq $t0, $t1, handle_output_file          # If choice is '2', go to output to file handling

    li $t1, 'f'                               # ASCII for lowercase 'f'
    beq $t0, $t1, handle_output_file          # If choice is 'f', handle file output

    li $t1, 'F'                               # ASCII for uppercase 'F'
    beq $t0, $t1, handle_output_file          # If choice is 'F', handle file output

    li $t1, '3'                               # ASCII code for '3'
    beq $t0, $t1, handle_screen_output        # If choice is '3', handle screen output

    li $t1, 's'                               # ASCII for lowercase 's'
    beq $t0, $t1, handle_screen_output        # If choice is 's', handle screen output

    li $t1, 'S'                               # ASCII for uppercase 'S'
    beq $t0, $t1, handle_screen_output        # If choice is 'S', handle screen output

    li $t1, '4'                               # ASCII code for '4'
    beq $t0, $t1, handle_exit_program         # If choice is '4', handle program exit

    li $t1, 'e'                               # ASCII for lowercase 'e'
    beq $t0, $t1, handle_exit_program         # If choice is 'e', handle program exit

    li $t1, 'E'                               # ASCII for uppercase 'E'
    beq $t0, $t1, handle_exit_program         # If choice is 'E', handle program exit

    # If choice is invalid, print an error and redisplay the menu
    li $v0, 4                                 # Syscall for print string
    la $a0, error_invalid_choice              # Load address of the error message
    syscall
    j display_menu                            # Loop back to display the menu again

# Menu option handlers
handle_read_input:
    la $a0, input_file_flag
    lb $t0, 0($a0)
    bne $t0, $zero, refresh_variables
    j handle_reading
refresh_variables:
    move $s7, $ra
    jal refresh
    move $ra, $s7
 
handle_reading:
    # Prompt for the input file and call read_input_file
    la $a0, prompt_file_input                 # Load prompt for file input
    li $v0, 4
    syscall

    # Read the filename from the user
    la $a0, input_filename                    # Address of input_filename buffer
    li $a1, 64                                # Max characters to read
    li $v0, 8                                 # Syscall for reading string
    syscall

    # Trim newline character from the input filename
    la $a0, input_filename                    # Address of filename
    jal trim_newline                          # Call trim_newline to clean up input

    # Call read_input_file to read and validate the file contents
    la $a0, input_filename                    # Address of filename
    jal read_input_file                       # Call read_input_file procedure
    jal print_systems
    jal solve_systems
    la $a0, input_file_flag
    li $t0, 1
    sb $t0, 0($a0)
    j display_menu                            # Return to menu after operation

handle_output_file:
    move $s7, $ra
    la $a0, input_file_flag
    lb $t0, 0($a0)
    beqz $t0, not_ready_yet

    # Print the output filename prompt
    la $a0, output_filename_prompt   # Address of the prompt string
    li $v0, 4                       # Syscall for print string
    syscall

    # Read the output filename from the user
    la $a0, output_filename         # Address of the output filename buffer
    li $a1, 64                      # Max size of the filename
    li $v0, 8                       # Syscall for read string
    syscall

    # Trim the newline character from the output filename
    la $a0, output_filename         # Address of the filename string
    jal trim_newline                # Call the trim_newline procedure

    # Open the file for writing
    li $v0, 13                      # Syscall for open file
    la $a0, output_filename         # Address of the filename string
    li $a1, 1                       # Open in write mode
    li $a2, 644                     # File permissions (rw-r--r--)
    syscall
    move $t0, $v0                   # Store the file descriptor in $t0

    # Check if the file was opened successfully
    bltz $t0, file_open_error       # If file descriptor < 0, handle error
    
    #la $a3, output_buffer
    #jal count_buffer
    #move $ra, $s7
    
    # Write the output buffer to the file
    li $v0, 15                      # Syscall for write file
    move $a0, $t0                   # File descriptor
    la $a1, output_buffer           # Address of the buffer to write
    li $a2, 128
    syscall

    # Close the file
    li $v0, 16                      # Syscall for close file
    move $a0, $t0                   # File descriptor
    syscall

    j display_menu                  # Return to menu after operation
handle_screen_output:
    
    la $a0, input_file_flag
    lb $t0, 0($a0)
    beqz $t0, not_ready_yet
    
    la $a0, output_buffer
    li $v0, 4
    syscall
    
    j display_menu                            # Return to menu after operation

not_ready_yet:
    la $a0, read_file_first
    li $v0, 4
    syscall
    j display_menu

handle_exit_program:
    # Code to exit the program
    li $v0, 10                                # Syscall for exit
    syscall

# Procedure to trim newline characters from the end of a string
# Input: $a0 - address of the string to be trimmed
# Output: None (modifies the string in place)
trim_newline:
    add $t0, $zero, $a0            # Copy the address of the string to $t0 for traversal

trim_loop:
    lb $t1, 0($t0)                 # Load the current character
    beq $t1, 0, end_trim           # If we reach the null terminator, we're done
    addi $t0, $t0, 1               # Move to the next character
    j trim_loop                    # Repeat until we reach the end of the string

# Backtrack to remove the newline character
end_trim:
    addi $t0, $t0, -1              # Go back one position to the last character
    lb $t1, 0($t0)                 # Load the last character
    li $t2, 10                     # ASCII value for newline character
    bne $t1, $t2, trim_done        # If it's not a newline, we're done
    sb $zero, 0($t0)               # Replace newline with null terminator if found

trim_done:
    jr $ra                          # Return from the procedure

# Error handling for format issues in equations
format_error:
    li $v0, 4                              # Syscall to print error message
    la $a0, error_format                   # Load error message
    syscall
    j close_file                           # Close the file and return to menu

# Procedure to read and validate equations from an input file
# Input: $a0 - address of the filename string
# Output: None (modifies arrays for x, y, z coefficients, and results)
read_input_file:
    move $k1, $ra
    # Open the file in read mode
    li $v0, 13                             # Syscall for open file
    la $a0, input_filename                 # Load the filename address
    li $a1, 0                              # Open in read-only mode
    li $a2, 0                              # Default permissions (not used in read-only mode)
    syscall
    move $s0, $v0                          # Store file descriptor in $s0

    # Check if file opened successfully
    bltz $s0, file_open_error              # If file descriptor < 0, handle file error

    # Read the entire file into buffer and parse as separate systems
    li $v0, 14                             # Syscall to read file
    move $a0, $s0                          # File descriptor
    la $a1, input_buffer                   # Address to load file contents
    li $a2, 500                            # Max characters to read
    syscall
    move $t0, $v0                          # Store read byte count

    # If end of file reached without reading, close file
    blez $t0, close_file

    # Call parse_systems to parse all systems in buffer
    la $a0, input_buffer                   # Address of buffer holding file contents
    jal parse_systems                      # Parse systems
    move $ra, $k1
    j close_file                           # Close file after reading

close_file:
    li $v0, 16                             # Syscall for close file
    move $a0, $s0                          # File descriptor
    syscall
    jr $ra                                 # Return to caller

file_open_error:
    # Print file read error message and exit
    li $v0, 4                              # Syscall for print string
    la $a0, error_file_read                # Load error message
    syscall
    j close_file                           # Go to close file and exit

# Procedure to parse multiple systems from buffer
# Input: $a0 - address of input buffer holding file contents
# Output: None (populates arrays for each system and equation)
parse_systems:
    move $k0, $ra
    # Initialize pointers and counters for parsing systems
    li $t9, 0                              # Reset system counter
    la $s1, coeff_array_x                  # Initialize pointer to coefficient x array
    la $s2, coeff_array_y                  # Initialize pointer to coefficient y array
    la $s3, coeff_array_z                  # Initialize pointer to coefficient z array
    la $s4, results_array                  # Initialize pointer to results array
    la $s5, system_type_array              # Initialize pointer to system types array
    li $t0, 0                              # Reset equation counter
    xor $t1, $t1, $t1                      # Clear z_read flag
    lb $t8, 0($a0)
    beqz $t8, parse_end
    lb $t9, system_counter                 # Load current system counter
    addi $t9, $t9, 1                       # Increment system counter
    sb $t9, system_counter                 # Store updated system counter
   
parse_line:
    lb $t8, 0($a0)                         # Load next character
    beqz $t8, parse_end                    # End of buffer reached, stop parsing

    # Handle new line (0xD 0xA) for separating systems and equations
    li $t7, 0xD                            # ASCII for carriage return
    beq $t8, $t7, check_line_feed          # If 0xD found, check next char
    li $t7, 0xA                            # ASCII for line feed
    beq $t8, $t7, handle_new_system        # If 0xA found, process as new system

    # Ignore spaces
    li $t7, ' '                            # ASCII for space
    beq $t8, $t7, next_char                # Skip spaces

    # Parse the line as an equation
    jal validate_and_parse_line            # Call line parser
    move $ra, $k0
    
    # Next line for parsing
    j next_char

check_line_feed:
    addi $a0, $a0, 1                       # Advance to next character
    lb $t8, 0($a0)                         # Load next character
    li $t7, 0xA                            # ASCII for line feed
    bne $t8, $t7, format_error             # If not 0xA, invalid line break

handle_new_system:
    addi $s5, $s5, 1                       # Advance system type pointer
    li $t0, 0                              # Reset equation counter
    lb $t9, system_counter                 # Load current system counter
    addi $t9, $t9, 1                       # Increment system counter
    sb $t9, system_counter                 # Store updated system counter
   
    j next_char                            # Continue to the next character

next_char:
    addi $a0, $a0, 1                       # Move to next character
    j parse_line                           # Continue parsing lines

parse_end:
    jr $ra                                 # Return to caller

# Procedure to validate and parse a single line for an equation
# Input: $a0 - address of input buffer line
# Output: Sets coefficients in arrays and indicates format errors
validate_and_parse_line:
    # Initialize flags for variables and signs
    sb $zero, x_read                       # Clear x_read flag
    sb $zero, y_read                       # Clear y_read flag
    sb $zero, z_read                       # Clear z_read flag
    sb $zero, equals_read                  # Clear equals_read flag
    li $t3, 0                              # Coefficient for x
    li $t4, 0                              # Coefficient for y
    li $t5, 0                              # Coefficient for z
    li $t6, 0                              # Result (right-hand side of equation)
    li $t7, 1                              # Default sign positive
    xor $t2, $t2, $t2                      # Clear current coefficient accumulator

parse_terms:
    lb $t8, 0($a0)                         # Load next character
    beqz $t8, validate_store               # End of line, validate and store results

    # Handle newline characters (0xD 0xA for end of equation)
    li $t9, 0xD                            # ASCII for carriage return
    beq $t8, $t9, check_line_feed1

    li $t9, 0xA                            # ASCII for line feed
    beq $t8, $t9, validate_store                # End of equation, validate and store

    # Ignore spaces
    li $t9, ' '                            # ASCII for space
    beq $t8, $t9, next_term                     # Skip spaces without error

    # Handle signs
    li $t9, '+'                            # ASCII for '+'
    beq $t8, $t9, set_positive

    li $t9, '-'                            # ASCII for '-'
    beq $t8, $t9, set_negative

    # Handle variables (x, y, z)
    li $t9, 'x'
    beq $t8, $t9, check_x                       # Process x variable

    li $t9, 'y'
    beq $t8, $t9, check_y                       # Process y variable

    li $t9, 'z'
    beq $t8, $t9, check_z                       # Process z variable

    # Handle equals sign
    li $t9, '='
    beq $t8, $t9, check_equals                  # Process equals sign

    # Handle digits
    li $t9, '0'
    bge $t8, $t9, check_digit_end          # Check if character is digit

    # Invalid character
    j format_error

set_positive:
    li $t7, 1                              # Set sign to positive
    j next_term

set_negative:
    li $t7, -1                             # Set sign to negative
    j next_term

check_digit_end:
    li $t9, '9'
    ble $t8, $t9, process_digit            # Process if character is digit
    j format_error                         # If not digit, format error

process_digit:
    sub $t8, $t8, '0'                      # Convert ASCII to integer
    mul $t2, $t2, 10                       # Shift previous value in $t2 by multiplying by 10
    add $t2, $t2, $t8                      # Add the new digit to $t2
    j next_term

check_x:
    lb $t9, x_read                         # Check if x has already been read
    bne $t9, $zero, format_error           # If x already read, format error
    sb $t7, x_read                         # Mark x as read
    beqz $t2, set_default_x                # If no value accumulated, default to 1
    mul $t3, $t2, $t7                      # Store coefficient for x
    j reset_accumulator

check_y:
    lb $t9, y_read                         # Check if y has already been read
    bne $t9, $zero, format_error           # If y already read, format error
    sb $t7, y_read                         # Mark y as read
    beqz $t2, set_default_y                # If no value accumulated, default to 1
    mul $t4, $t2, $t7                      # Store coefficient for y
    j reset_accumulator

check_z:
    lb $t9, z_read                         # Check if z has already been read
    bne $t9, $zero, format_error           # If z already read, format error
    sb $t7, z_read                         # Mark z as read
    beqz $t2, set_default_z                # If no value accumulated, default to 1
    mul $t5, $t2, $t7                      # Store coefficient for z
    j reset_accumulator

set_default_x:
    li $t2, 1                              # Default coefficient is 1
    mul $t3, $t2, $t7                      # Apply the sign and set the coefficient
    j reset_accumulator

set_default_y:
    li $t2, 1                              # Default coefficient is 1
    mul $t4, $t2, $t7                      # Apply the sign and set the coefficient
    j reset_accumulator
    
set_default_z:
    li $t2, 1                              # Default coefficient is 1
    mul $t5, $t2, $t7                      # Apply the sign and set the coefficient
    j reset_accumulator
    
reset_accumulator:
    xor $t2, $t2, $t2                      # Clear accumulator
    li $t7, 1                              # Reset sign
    j next_term

check_equals:
    lb $t9, equals_read                    # Check if equals has already been read
    bne $t9, $zero, format_error           # If equals already read, format error
    sb $t7, equals_read                    # Mark equals as read
    xor $t2, $t2, $t2                      # Clear accumulator
    li $t7, 1                              # Reset sign
    j next_term

check_line_feed1:
    addi $a0, $a0, 1                       # Advance to next character
    lb $t8, 0($a0)                         # Load next character
    li $t9, 0xA                            # ASCII for line feed
    bne $t8, $t9, format_error                  # If not 0xA, invalid line break
    j validate_store

next_term:
    addi $a0, $a0, 1                       # Advance to next character
    j parse_terms

validate_store:
    mul $t6, $t2, $t7
    # Validate that x and y are present
    lb $t8, x_read
    beqz $t8, format_error                 # If x is missing, format error

    lb $t8, y_read
    beqz $t8, format_error                 # If y is missing, format error

    # Determine system type based on z_read flag
    lb $t8, z_read
    beqz $t8, store_two_var                # If z is missing, it's a 2-variable system
    j store_three_var                      # If z is present, it's a 3-variable system

store_two_var:
    sb $zero, 0($s5)                       # Store system type as 0 (2-variable)
    j store_coefficients

store_three_var:
    li $t8, 1                              # System type for 3-variable system
    sb $t8, 0($s5)                         # Store system type as 1 (3-variable)
    
store_coefficients:
    sb $t3, 0($s1)                         # Store x coefficient
    sb $t4, 0($s2)                         # Store y coefficient
    sb $t5, 0($s3)                         # Store z coefficient
    sb $t6, 0($s4)                         # Store result
    addi $s1, $s1, 1                       # Advance x array pointer
    addi $s2, $s2, 1                       # Advance y array pointer
    addi $s3, $s3, 1                       # Advance z array pointer
    addi $s4, $s4, 1                       # Advance results array pointer
    jr $ra                                 # Return to caller
    
 
# Procedure to print all systems from the arrays
# Input: Coefficient arrays, system type array, and results array
# Output: Nicely formatted system equations
print_systems:
    la $t0, coeff_array_x                  # Pointer to x coefficients
    la $t1, coeff_array_y                  # Pointer to y coefficients
    la $t2, coeff_array_z                  # Pointer to z coefficients
    la $t3, results_array                  # Pointer to results
    la $t4, system_type_array              # Pointer to system types
    lb $t5, system_counter                 # Load total number of systems
    li $t6, 0                              # System index starts at 1

    subi $t0, $t0, 1
    subi $t1, $t1, 1
    subi $t2, $t2, 1
    subi $t3, $t3, 1
    subi $t4, $t4, 1
print_systems_loop:
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    addi $t2, $t2, 1
    addi $t3, $t3, 1
    addi $t4, $t4, 1
    
    bge $t6, $t5, print_systems_done
    addiu $t6, $t6, 1
    li $t8, 0
    
    la $a0, label_system
    li $v0, 4
    syscall
    
    li $v0, 1
    move $a0, $t6
    syscall
    
    li $v0, 4
    la $a0, newline_str
    syscall
    
    lb $t7, 0($t4)
    beq $t7, 0, print_two_vars

print_three_vars:
    addiu $t8, $t8, 1
    lb $t9, 0($t0)
    beq $t9, 1, print_3x
    move $a0, $t9
    li $v0, 1
    syscall
print_3x:
    la $a0, label_x
    li $v0, 4
    syscall
    
    la $a0, space_str
    syscall
    
    la $a0, operator_plus
    syscall
    
    la $a0, space_str
    syscall
    
    lb $t9, 0($t1)
    beq $t9, 1, print_3y
    move $a0, $t9
    li $v0, 1
    syscall
print_3y:
    la $a0, label_y
    li $v0, 4
    syscall
    
    la $a0, space_str
    syscall
    
    la $a0, operator_plus
    syscall
    
    la $a0, space_str
    syscall
    
    lb $t9, 0($t2)
    beq $t9, 1, print_3z
    move $a0, $t9
    li $v0, 1
    syscall
print_3z:
    
    la $a0, label_z
    li $v0, 4
    syscall
    
    la $a0, operator_equals
    syscall
    
    lb $a0, 0($t3)
    li $v0, 1
    syscall
    
    la $a0, newline_str
    li $v0, 4
    syscall
    beq $t8, 3, print_systems_loop
    addiu $t0, $t0, 1
    addiu $t1, $t1, 1
    addiu $t2, $t2, 1
    addiu $t3, $t3, 1
    j print_three_vars

print_two_vars:
    addiu $t8, $t8, 1
    lb $t9, 0($t0)
    beq $t9, 1, print_2x
    move $a0, $t9
    li $v0, 1
    syscall
print_2x:
    la $a0, label_x
    li $v0, 4
    syscall
    
    la $a0, space_str
    syscall
    
    la $a0, operator_plus
    syscall
    
    la $a0, space_str
    syscall
    
    lb $t9, 0($t1)
    beq $t9, 1, print_2y
    move $a0, $t9
    li $v0, 1
    syscall
print_2y:
    la $a0, label_y
    li $v0, 4
    syscall
    
    la $a0, operator_equals
    syscall
    
    lb $a0, 0($t3)
    li $v0, 1
    syscall
    
    la $a0, newline_str
    li $v0, 4
    syscall
    
    beq $t8, 2, print_systems_loop
    addiu $t0, $t0, 1
    addiu $t1, $t1, 1
    addiu $t2, $t2, 1
    addiu $t3, $t3, 1
    j print_two_vars

print_systems_done:
    jr $ra
    
solve_systems:
    move $k0, $ra
    la $s0, coeff_array_x                  # Initialize pointer to coefficient x array
    la $s1, coeff_array_y                  # Initialize pointer to coefficient y array
    la $s2, coeff_array_z                  # Initialize pointer to coefficient z array
    la $s3, results_array                  # Initialize pointer to results array
    la $s4, system_type_array              # Initialize pointer to system types array
    la $a1, output_buffer
    li $s5, 0
check_system:
    
    lb $k1, system_counter
    bge $s5, $k1, solving_done
    addiu $s5, $s5, 1
    
    lb $t0, 0($s4)
    beq $t0, 0, solve_two_vars
    
solve_three_vars:
        
    jal determinant_3x3      # find det(A)
    move $ra, $k0
    
    sw $v0, det_a
    
    move $t0, $s0
    move $s0, $s3
    move $s3, $t0
    
    jal determinant_3x3     # find det(A1)
    move $ra, $k0
    
    sw $v0, det_a1
    
    move $t0, $s0
    move $s0, $s3
    move $s3, $t0
    
    move $t0, $s1
    move $s1, $s3
    move $s3, $t0
    
    jal determinant_3x3    # find det(A2)
    move $ra, $k0
    
    sw $v0, det_a2
    
    move $t0, $s1
    move $s1, $s3
    move $s3, $t0
    
    move $t0, $s2
    move $s2, $s3
    move $s3, $t0
    
    jal determinant_3x3
    move $ra, $k0
    
    sw $v0, det_a3
    
    move $t0, $s2
    move $s2, $s3
    move $s3, $t0
    
    jal extract_three_var_answers
    move $ra, $k0
    
    addiu $s0, $s0, 3
    addiu $s1, $s1, 3
    addiu $s2, $s2, 3
    addiu $s3, $s3, 3
    addiu $s4, $s4, 1
    
    j check_system
  
solve_two_vars:
    
    jal determinant_2x2    # find det(A)
    move $ra, $k0
    
    sw $v0, det_a
    
    move $t0, $s0
    move $s0, $s3
    move $s3, $t0
    
    jal determinant_2x2   # find det(A1)
    move $ra, $k0
    
    sw $v0, det_a1
    
    move $t0, $s0
    move $s0, $s3
    move $s3, $t0
    
    move $t0, $s1
    move $s1, $s3
    move $s3, $t0
    
    jal determinant_2x2    # find det(A2)
    move $ra, $k0
    
    sw $v0, det_a2
    
    move $t0, $s1
    move $s1, $s3
    move $s3, $t0
    
    jal extract_two_var_answers
    move $ra, $k0
    
    addiu $s0, $s0, 2
    addiu $s1, $s1, 2
    addiu $s2, $s2, 2
    addiu $s3, $s3, 2
    addiu $s4, $s4, 1
    j check_system

solving_done:
    jr $ra


extract_three_var_answers:
    move $t9, $ra
    li $a0, 'X'
    PRINT_VAR_RES $a0, $a1
    
    lw $t1, det_a
    lw $t0, det_a1
    
    jal division 
    move $ra, $t9
    
    move $a3, $v0
    
    la $a2, temp_buffer
    jal string_reset
    move $ra, $t9
    
    la $a2, temp_buffer
    move $v0, $a3
    
    jal parse_integer
    move $ra, $t9
    
    la $a2, temp_buffer
    jal copy_string
    move $ra, $t9
    
    jal test_print_denominator
    move $ra, $t9
    
    li $a0, '\n'
    MOVE_MEM $a0, $a1
    
    li $a0, 'Y'
    PRINT_VAR_RES $a0, $a1
    
    lw $t1, det_a
    lw $t0, det_a2
    
    jal division 
    move $ra, $t9
    
    move $a3, $v0
    
    la $a2, temp_buffer
    jal string_reset
    move $ra, $t9
    
    la $a2, temp_buffer
    move $v0, $a3
    
    jal parse_integer
    move $ra, $t9
    
    la $a2, temp_buffer
    
    jal copy_string
    move $ra, $t9
    
    jal test_print_denominator
    move $ra, $t9
    
    li $a0, '\n'
    MOVE_MEM $a0, $a1
    
    li $a0, 'Z'
    PRINT_VAR_RES $a0, $a1
    
    lw $t1, det_a
    lw $t0, det_a3
    
    jal division 
    move $ra, $t9
   
    move $a3, $v0
    
    la $a2, temp_buffer
    jal string_reset
    move $ra, $t9
   
    move $v0, $a3
    la $a2, temp_buffer
    jal parse_integer
    move $ra, $t9
    
    la $a2, temp_buffer

    jal copy_string
    move $ra, $t9
    
    jal test_print_denominator
    move $ra, $t9
    
    li $a0, '\n'
    MOVE_MEM $a0, $a1
    MOVE_MEM $a0, $a1
    
    jr $ra


extract_two_var_answers:
    
    move $t9, $ra
    li $a0, 'X'
    PRINT_VAR_RES $a0, $a1
    
    lw $t1, det_a
    lw $t0, det_a1
    
    jal division 
    move $ra, $t9
    
    move $a3, $v0
    
    la $a2, temp_buffer
    jal string_reset
    move $ra, $t9
    
    la $a2, temp_buffer
    move $v0, $a3
    
    jal parse_integer
    move $ra, $t9
    
    la $a2, temp_buffer
    jal copy_string
    move $ra, $t9
    
    jal test_print_denominator
    move $ra, $t9
    
    li $a0, '\n'
    MOVE_MEM $a0, $a1
    
    li $a0, 'Y'
    PRINT_VAR_RES $a0, $a1
    
    lw $t1, det_a
    lw $t0, det_a2
    
    jal division 
    move $ra, $t9
    
    move $a3, $v0
    
    la $a2, temp_buffer
    jal string_reset
    move $ra, $t9
    
    la $a2, temp_buffer
    move $v0, $a3
    
    jal parse_integer
    move $ra, $t9
    
    la $a2, temp_buffer
    
    jal copy_string
    move $ra, $t9
    
    jal test_print_denominator
    move $ra, $t9
    
    li $a0, '\n'
    MOVE_MEM $a0, $a1
    MOVE_MEM $a0, $a1
    
    jr $ra

test_print_denominator:
    move $t7, $ra
    
    beq $v1, 1, no_print_needed
    li $a0, '/'
    MOVE_MEM, $a0, $a1
    
    la $a2, temp_buffer
    jal string_reset
    move $ra, $t7
    
    la $a2, temp_buffer
    move $v0, $v1
    
    jal parse_integer
    move $ra, $t7
    
    la $a2, temp_buffer
    
    jal copy_string
    move $ra, $t7
    
no_print_needed:
    jr $ra

# Function to do division
# Input: $t0 = dividend, $t1 = divisor
# Output:
#   $v0 = numerator (or integer result if exact division)
#   $v1 = denominator (0 if exact division)
division:
    move $t8, $ra           # Save return address
    beqz $t1, division_by_zero_error  # Check for division by zero
    
    # Perform division to check if the result is exact
    div $t0, $t1
    
    mfhi $t2                # Get the remainder
    mflo $v0                # Get the quotient
    
    beqz $t2, exact_division # If remainder is 0, it's an exact division

    # Handle fractional division
    move $v0, $t0           # Numerator
    move $v1, $t1           # Denominator
    move $t5, $t1
    # Compute GCD of numerator and denominator
    jal gcd                 # Call GCD procedure
    move $ra, $t8           # Restore return address

    # Simplify the fraction
    div $v0, $v0, $v1       # Divide numerator by GCD
    mflo $v0
    div $v1, $t5, $v1       # Divide denominator by GCD
    mflo $v1
    jr $ra                  # Return to the caller

exact_division:
    li $v1, 1               # Denominator set to 0
    jr $ra                  # Return to the caller

division_by_zero_error:
    # Handle division by zero error (optional error handling)
    li $v0, 4
    la $a0, error_div_zero  # Load error message
    syscall
    li $v0, 10              # Exit program
    syscall

# Procedure to calculate GCD using the Euclidean algorithm
# Input: $v0 = numerator, $v1 = denominator
# Output: $v1 = GCD of numerator and denominator
gcd:
    move $t0, $v0           # Copy numerator to $t0
    move $t1, $v1           # Copy denominator to $t1

gcd_loop:
    beqz $t1, gcd_done      # If $t1 is 0, GCD is in $t0
    div $t0, $t1
    mfhi $t2                # Get the remainder
    move $t0, $t1           # $t0 = $t1
    move $t1, $t2           # $t1 = remainder
    j gcd_loop

gcd_done:
    move $v1, $t0           # GCD is in $t0
    jr $ra                  # Return to the caller



# Function to calculate determinant for 3x3 matrix
# Input: $s0 = pointer to first col, $s1 = pointer to second col, $s2 = pointer to third col
# Output: $v0 = determinant value
determinant_3x3:
    move $k1, $ra
    
    lb $t0, 0($s0)
    
    lb $t1, 1($s1)
    lb $t2, 1($s2)
    lb $t3, 2($s1)
    lb $t4, 2($s2)
    
    jal determinant_2x2_3x3
    move $ra, $k1
    
    mult $t0, $t1
    mflo $t7        
    
    lb $t0, 0($s1)
    
    lb $t1, 1($s0)
    lb $t2, 1($s2)
    lb $t3, 2($s0)
    lb $t4, 2($s2)
    
    jal determinant_2x2_3x3
    move $ra, $k1
    
    mult $t0, $t1
    mflo $t8
    
    lb $t0, 0($s2)
    
    lb $t1, 1($s0)
    lb $t2, 1($s1)
    lb $t3, 2($s0)
    lb $t4, 2($s1)
    
    jal determinant_2x2_3x3
    move $ra, $k1
    
    mult $t0, $t1
    mflo $t9
    
    sub $v0, $t7, $t8
    add $v0, $v0, $t9
    
    jr $ra             # Return to caller

# $t1   $t2 
# $t3   $t4
determinant_2x2_3x3:
    mult $t1, $t4
    mflo $t5
    mult $t3, $t2
    mflo $t6
    
    sub $t1, $t5, $t6
    jr $ra

# Function to calculate determinant for 2x2 matrix
# Input: $s0 = pointer to first col, $s1 = pointer to second col
# Output: $v0 = determinant value
determinant_2x2:
    
    lb $t0, 0($s0)
    lb $t1, 0($s1)
    lb $t2, 1($s0)
    lb $t3, 1($s1)
    
    mult $t0, $t3
    mflo $t0
    
    mult $t1, $t2
    mflo $t1
    
    sub $v0, $t0, $t1
    
    jr $ra


# Function to reset a string
# Input: $a2 = pointer to the target string
# Output: string is empty
string_reset:

loop_reset:
    lb $t8, 0($a2)
    beqz $t8, reset_string_done
    sb $zero, 0($a2)
    addiu $a2, $a2, 1
    addiu $t6, $t6, 1
reset_string_done:
    jr $ra


# Procedure to copy a null-terminated string
# Input: 
#   $a2 - address of the source string
#   $a1 - address of the destination string
# Output:
#   Copies the null-terminated string from $a2 to $a1
copy_string:
    loop_copy:
        lb $t0, 0($a2)      # Load a byte from the source string
        sb $t0, 0($a1)      # Store the byte into the destination string
        beq $t0, $zero, done_copy # If null terminator is encountered, end copy
        addiu $a2, $a2, 1   # Move to the next byte in the source string
        addiu $a1, $a1, 1   # Move to the next byte in the destination string
        j loop_copy         # Repeat for the next byte
    
    done_copy:
        jr $ra              # Return to the caller


# Function to parse an integer into a string
# Input: $v0 contains the integer, $a2 contains the address of the string buffer
# Output: The integer is converted to a string at the address in $a2
parse_integer:
    move $t0, $v0           # Copy the input integer to $t0
    li $t1, 0               # Initialize digit counter
    li $t2, 0               # Flag for negative number (0 = positive, 1 = negative)

    # Handle negative numbers
    bltz $t0, handle_negative

convert_integer:
    beqz $t0, handle_zero   # If $t0 is zero, handle the special case
    divu $t0, $t0, 10       # Divide the number by 10
    mfhi $t3                # Get the remainder (last digit)
    addiu $t3, $t3, '0'     # Convert digit to ASCII
    sb $t3, 0($a2)          # Store the digit as a character
    addiu $a2, $a2, 1       # Move pointer forward in the buffer
    mflo $t0                # Update $t0 with the quotient
    addiu $t1, $t1, 1       # Increment digit counter
    bnez $t0, convert_integer # Repeat until $t0 becomes zero

    # Handle negative number case
    bnez $t2, add_minus_sign
    j finalize_string

handle_negative:
    li $t2, 1               # Set negative flag
    subu $t0, $zero, $t0    # Make the number positive
    j convert_integer

add_minus_sign:
    li $t3, '-'             # Load ASCII for minus sign
    sb $t3, 0($a2)          # Store the minus sign
    addiu $a2, $a2, 1       # Move pointer forward in the buffer

finalize_string:
    sb $zero, 0($a2)        # Null-terminate the string
    sub $a2, $a2, $t1       # Move pointer back to the start of the string
    bnez $t2, adjust_pointer # Adjust for negative sign if present
    jr $ra                  # Return to the caller

adjust_pointer:
    sub $a2, $a2, 1         # Include the minus sign in the pointer adjustment
    jr $ra

handle_zero:
    li $t3, '0'             # ASCII for '0'
    sb $t3, 0($a2)          # Store '0' in the buffer
    addiu $a2, $a2, 1       # Move pointer forward
    j finalize_string

count_buffer:
    li $a2, 5   
count_loop:
    lb $t0, 0($a3)
    beqz $t0, counting_done
    addiu $a2, $a2, 1
    addiu $a3, $a3, 1
    j count_loop
counting_done:     
    jr $ra

refresh:
    move $s6, $ra
    
    la $a2, input_filename
    jal string_reset
    la $a2, output_filename
    jal string_reset
    la $a2, input_buffer
    jal string_reset
    la $a2, output_buffer
    jal string_reset
    la $a0, input_file_flag
    li $t0, 0
    sb $t0, 0($a0)
    sb $t0, system_counter
    
    jr $s6
