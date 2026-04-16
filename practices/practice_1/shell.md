*Enter into main server*

ssh avt341-v9@217.71.138.1 -p 55777
k5ioyyAO8cR6

*Enter into sub-server*

ssh root@172.16.8.149
rebustubus

# From remote
scp -P 55777 username@remote_host:/path/to/remote/file.txt /path/to/local/directory/


# From local
scp -P 55777 -r /path/to/local/directory/ username@remote_host:/path/to/remote/directory/

