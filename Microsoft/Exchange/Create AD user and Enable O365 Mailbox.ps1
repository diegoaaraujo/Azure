#  
#add exchange snap-in
#Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn;

#get username with input
"";
"----- by Flo Faber -----";
"";


#get first and lastname with input
$firstname = Read-Host "First Name";
$lastname = Read-Host "Last Name";

$username = $firstname + "." + $lastname;
$username_domain = $username + '@wdrc.qld.gov.au';

$name = $firstname + $lastname;
$displayname = $firstname + " " + $lastname;

#get password with input
$password = Read-Host "Password" -AsSecureString;

#get Organisation Unit with input
#$ou_input = Read-Host "Organisation Unit";
#$ou = "OU=$ou_input,DC=AD,DC=faber,DC=int,DC=local";

#Add AD-User and Mailbox
New-ADUser -Name $displayname -GivenName $firstname -Surname $lastname -SamAccountName $username -UserPrincipalName $username_domain -AccountPassword $password -PassThru | Enable-ADAccount;

#Enable created mailbox
Enable-Mailbox -Identity $username;

cmd /c pause | out-null