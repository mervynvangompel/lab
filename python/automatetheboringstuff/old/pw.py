user_name = "Mervyn"
password = "swordfish"
count = 1
try_again = "Yes"

print("Hello " + user_name)

while user_name == "Mervyn" and try_again == "Yes":

    pw_input = input("Please enter password > ")
    if pw_input == password:
        print("Access granted")
        break
    else:
        print("Access denied")
        count = count + 1
        if count <= 3:
            try_again = input("Try again (Yes / No)? > ")
        else:
            print("Too many incorrect tries!")
            break
print("Goodbye!")
