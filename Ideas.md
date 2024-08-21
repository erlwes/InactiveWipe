# To-do
* After hitting ok in gridview - let user choose beween actions:
  * Copy UPN to clipboard
  * Save complete result to CSV-file
  * Save UPN to CSV-file ready to be uploaded in Entra ID as bulk operation (remove or disable)

Present a save file dialog using pre-defined .Net classes.

# Maybe
* Swap modes between members and guests? IT-tends to have better control over their member users, since these are created by IT -> Experimental parameter added for cleaning members
* Insight: Licenced guests. Save money
* Sanity checks/help: Checking activity for disabled users as well? Need to calculate days from last sign-in for disabled users in order to do this. Will not affect performence by much.
* Sanity checks/help: Check that "never signed in/invitation not accepted" users where invitied or created less than 180 days ago (follow same threshold as inactive). Calculate days since createdtime.

# Done
* Use @odata.nextLink to get results above 999 🤦‍♂️ ✅
* Simplify with only one gauge displaying total potential for removal, rather than per step? ✅
* Insight: List all unique external email domains across guests. Attack surface ✅
