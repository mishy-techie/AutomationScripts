"""
Password Generator
------------------
Generates a random password using Python's
cryptographically secure secrets module.

Main concept:
- Randomization

Features:
- Custom password length
- Uppercase letters
- Lowercase letters
- Numbers
- Special characters
- Cryptographically secure randomness

Requires:
- Python 3+
"""

import string
import secrets


# -------------------------------------------------------
# Configuration
# -------------------------------------------------------

DEFAULT_LENGTH = 16

# Character groups that can be used in the password.
UPPERCASE = string.ascii_uppercase
LOWERCASE = string.ascii_lowercase
NUMBERS = string.digits
SPECIAL = "!@#$%^&*()-_=+[]{}"

# Combine all character groups.
ALL_CHARACTERS = (
    UPPERCASE +
    LOWERCASE +
    NUMBERS +
    SPECIAL
)


# -------------------------------------------------------
# Ask for password length
# -------------------------------------------------------

user_input = input(
    f"Enter password length (default: {DEFAULT_LENGTH}): "
)

# Use the default length if the user presses Enter.
if user_input.strip() == "":
    length = DEFAULT_LENGTH

else:

    try:
        length = int(user_input)

    except ValueError:
        print("Invalid length.")
        exit()


# -------------------------------------------------------
# Validate password length
# -------------------------------------------------------

if length < 8:

    print("Password length must be at least 8 characters.")
    exit()


# -------------------------------------------------------
# Generate the password
# -------------------------------------------------------

# secrets.choice() is designed for security-sensitive
# random values such as passwords and tokens.

password = "".join(
    secrets.choice(ALL_CHARACTERS)
    for _ in range(length)
)


# -------------------------------------------------------
# Display password
# -------------------------------------------------------

print()
print("===========================================")
print(" Password Generator")
print("===========================================")
print()

print("Generated Password:")
print(password)

print()
print(f"Length: {length}")
print()
