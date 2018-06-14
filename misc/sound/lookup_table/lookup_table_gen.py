bram_file = open("lookup_table.coe", "w")
bram_sim_file = open("lookup_table.dat", "w")

sim_header = "@0000/n"
synth_header = "memory_initialization_radix=16;\nmemory_initialization_vector=\n"
CLOCKRATE = 33000000 #sampling at on a 48 khz Clock

bram_file.write(synth_header)
bram_sim_file.write(sim_header)

for i in range(0,2**11 - 1):
    frequency = float(2**17)/(2**11 - i)
    clocks_in_period = float(CLOCKRATE)/frequency
    hex_string = hex(int(clocks_in_period))    #convert to a string
    hex_string = hex_string[2:] #remove the "0x"
    bram_file.write(hex_string + ",\n")
    bram_sim_file.write(hex_string + "\n")

#the last value
frequency = float(2**17)
clocks_in_period = float(CLOCKRATE)/frequency
hex_string = hex(int(clocks_in_period))    #convert to a string
hex_string = hex_string[2:] #remove the "0x"
bram_file.write(hex_string)
bram_sim_file.write(hex_string)


