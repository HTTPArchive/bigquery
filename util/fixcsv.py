import fileinput
for line in fileinput.input():
    if line.endswith('\\\n'):
        line = line[:-2] + ','
    print(line),
