
nmap -O -sA 192.168.100.0/24
nmap -A -T4 -F 192.168.100.0/24


#Enable OS Detection with Nmap
nmap -O server2.tecmint.com

#Scan a Host to Detect Firewall
nmap -sA 192.168.0.101

#Scan a Host to check its protected by Firewall
nmap -PN 192.168.0.101

#Find out Live hosts in a Network
nmap -sP 192.168.0.*

#Perform a Fast Scan
nmap -F 192.168.0.101

#Find Nmap version
nmap -V

#Scan Ports Consecutively
#Use the “-r” flag to don’t randomize.
nmap -r 192.168.0.101

#Print Host interfaces and Routes
nmap --iflist

#Scan for specific Port
nmap -p 80 server2.tecmint.com

#Scan a TCP Port
nmap -p T:8888,80 server2.tecmint.com

#Scan a UDP Port
nmap -sU 53 server2.tecmint.com

#Find Host Services version Numbers
nmap -sV 192.168.0.101

#Scan remote hosts using TCP ACK (PA) and TCP Syn (PS)
#Sometimes packet filtering firewalls blocks standard ICMP ping requests, in that case, we can use TCP ACK and TCP Syn methods to scan remote hosts.
nmap -PS 192.168.0.101

#Scan Remote host for specific ports with TCP ACK
nmap -PA -p 22,80 192.168.0.101

#Scan Remote host for specific ports with TCP Syn
nmap -PS -p 22,80 192.168.0.101

#Perform a stealthy Scan
nmap -sS 192.168.0.101

#Check most commonly used Ports with TCP Syn
nmap -sT 192.168.0.101

#Perform a tcp null scan to fool a firewall
nmap -sN 192.168.0.101
