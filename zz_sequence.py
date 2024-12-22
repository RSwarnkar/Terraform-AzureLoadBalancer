import configparser
import os, math
import re
import pandas as pd

## -------------------------------------------------------------------------------
# This loop renames the *.tf file names
# e.g. 00-providers.tf --> providers.tf

for file in os.listdir("."):
    if file.endswith(".tf"):
        if m := re.match(r'\d+-([a-zA-Z0-9-_ ]+\.tf)', file):
            print("Renaming: ",file, " To ", m.group(1))
            os.rename(file, m.group(1))



## -------------------------------------------------------------------------------
# Read Configuration file - index.ini 
# The index.ini defines the sequence in while files should be named 

config = configparser.ConfigParser()
config.read('zz_sequence.ini')

tfFileSequence = config.get('TerraformFileSequence','filesequence').split('\n')
tfFileSequence = list(filter(None, tfFileSequence)) # Remove items with ''

# Zero-fill the sequence number foir the file to appear in-order: 
# If there are 14 files then the names should be from 00, 01, .., 13. 
number_of_digit = math.floor(math.log10(len(tfFileSequence))) + 1 


# Create a Dictionary from List of Filenames and Zero-Filled Sequence Number
filename_keys = []
sequence_values = []
for index, filename in enumerate(tfFileSequence):
    filename_keys.append(filename)
    sequence_values.append(str(index).zfill(number_of_digit))
    #print(f"Index: {str(index).zfill(number_of_digit)}, Value: {value}")

renaming_catalog = dict(zip(filename_keys, sequence_values))

df = pd.DataFrame({'Filename' : renaming_catalog.keys() , 'Zero-fill Sequence' : renaming_catalog.values() })
df


## -------------------------------------------------------------------------------

# Finally, rename files 
for file in os.listdir("."):
    if file.endswith(".tf"):
        new_file_name = renaming_catalog.get(file) + "-" + file
        print("Renaming ",file, " ---> ", new_file_name)
        os.rename(file, new_file_name)
        
