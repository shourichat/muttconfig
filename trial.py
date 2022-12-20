#!/usr/bin/python3

import datefinder

with open('email.txt', 'r') as file:
    input_string = file.read().replace('\n', ' ')

matches = datefinder.find_dates(input_string)

print("Possible dates extracted from the email.")
print("Choose the suitable one, or 0 if none.")
k=1;
matches = list(matches)
print(matches)

for match in matches:
     print(k, ":", match)
     k=k+1
entry = input("Which one?\n")
entry = int(entry)
entry = entry-1

print(matches[entry])
