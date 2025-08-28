name = input('Enter your name > ')
age = input('Enter your age > ')
age = int(age)
if name == 'Alice':
    print('Hi, Alice')
elif age < 12:
    print('You are not Alice, kiddo.')
elif age > 100:
    print('You are not Alice, grannie')
elif age > 2000:
    print('Unlike you, Alice is not an undead, immortal vampire')