while True:
    print("Who are you?")
    name = input (">")
    if name != "Joe":
        continue
    print("Hello Joe, what is the password?")
    password = input(">")
    if password == "swordfish":
        break
print("access granted")
