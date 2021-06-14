misc__newuid() { date +%s.%N|md5sum|cut -d\  -f1; }
