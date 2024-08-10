# To-do
* Insight: Licenced guests. Save money by wiping.
* Insight: List all unique external email domains across guests. Attack surfacee.

# Probably not
* Guests with rolles and memberships (would require more graph permissions i believe). Maybe not in this tool? KISS?

# Maybe
* Swap modes between members and guests? IT-tends to have better control over their member users, since these are created by IT. Tool is focused on guests per now.
* Sanity checks/help: Checking activity for disabled users as well? Need to calculate days from last sign-in for disabled users in order to do this. Will not affect performence by much.
* Sanity checks/help: Check that "never signed in/invitation not accepted" users where invitied or created less than 180 days ago (follow same threshold as inactive). Calculate days since createdtime.
* Simplify with only one gauge displaying total potential for removal, rather than per step?
