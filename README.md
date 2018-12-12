# Reset Password via Self Service for Technicians

a script that can be used in Self Service for your helpdesk technicians when a end-users his password is out of sync and is Filevault enabled.

In case that a user has changed his password (via NoMAD or sys prefs) that has been synced to your AD environment but the FileVault 2 Disk Encryption password has not changed you can use the script below.
or they simple dont know their password anymore after a good vacation.

In our situation when someone is unable to login with their own password we log in with or support account, log out to login windows with username / password field and then log in with their New / AD password, when logged in the tech launches self service and is loggin in with his tech credentials where the script is available, depends on your organisations needs.

The script below is designed for your helpdesk technicians and you can scope it to them so they can call it in via Self Service.
This also contains GUI pop-ups

Usage;
- Set an new password for your end user in AD.
- Log in with your local-admin account.
- Log out, and back in through network login with the end-users newest credentials.
- Run the script through Self Service.

