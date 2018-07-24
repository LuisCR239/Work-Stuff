Microsoft code modified to allow the backup of sql logins and passwords with newer versions of SQL Server
( SQL Server versions before 2012 stores passwords with an older algorithm, but since 2012, they use a newer algorithm that extends the quantity of characters used to store the password and the script provided by Microsoft does not handle the different versions )
