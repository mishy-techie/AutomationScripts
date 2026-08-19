<#
    Password Generator
    ------------------
    Generates a random password using a cryptographically
    secure random number generator.

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
    - PowerShell 7+
#>

# -------------------------------------------------------
# Configuration
# -------------------------------------------------------

$defaultLength = 16

# Characters that can be used in the password.
$uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
$lowercase = "abcdefghijklmnopqrstuvwxyz"
$numbers = "0123456789"
$special = "!@#$%^&*()-_=+[]{}"

# Combine all character groups.
$allCharacters = $uppercase + $lowercase + $numbers + $special

# -------------------------------------------------------
# Ask for password length
# -------------------------------------------------------

$inputLength = Read-Host "Enter password length (default: $defaultLength)"

# Use the default length if the user presses Enter.
if ([string]::IsNullOrWhiteSpace($inputLength)) {

    $length = $defaultLength

}
else {

    # Try to convert the input into an integer.
    if (-not [int]::TryParse($inputLength, [ref]$length)) {

        Write-Host "Invalid length."
        exit
    }
}

# -------------------------------------------------------
# Validate password length
# -------------------------------------------------------

if ($length -lt 8) {

    Write-Host "Password length must be at least 8 characters."
    exit
}

# -------------------------------------------------------
# Generate secure random characters
# -------------------------------------------------------

try {

    # RandomNumberGenerator provides cryptographically
    # secure random values.
    $random = [System.Security.Cryptography.RandomNumberGenerator]::Create()

    $passwordCharacters = New-Object System.Collections.Generic.List[char]

    for ($i = 0; $i -lt $length; $i++) {

        # Generate a secure random byte.
        $byte = New-Object byte[] 4

        $random.GetBytes($byte)

        # Convert the random bytes into an integer.
        $randomNumber = [BitConverter]::ToUInt32($byte, 0)

        # Select a character from the character set.
        $index = $randomNumber % $allCharacters.Length

        $passwordCharacters.Add(
            $allCharacters[$index]
        )

    }

    $password = -join $passwordCharacters

}
finally {

    # Release the random number generator.
    if ($null -ne $random) {
        $random.Dispose()
    }
}

# -------------------------------------------------------
# Display password
# -------------------------------------------------------

Write-Host ""
Write-Host "==========================================="
Write-Host " Password Generator"
Write-Host "==========================================="
Write-Host ""

Write-Host "Generated Password:"
Write-Host $password

Write-Host ""
Write-Host "Length: $length"
Write-Host ""
