sipx

This module almost deploys and configures a sipXecs from sipfoundry.org
Sadly there are some manual actions still to be done from the webgui.
I haven't found any alternative approaches yet to do this from the API.

Before you start there are a couple of assumptions I make.
This module is a replacement for the for sipxecs-setup-system  
However it only configures the sipx specific parts.  

I assume that you are using other modules to configure your network, dns, ntp, dhcpd tfpboot and vsftpd services.

And that you have a sipx package available in the repositories you use 
(e.g by adding  one of the ones listed on http://download.sipfoundry.org/pub/sipXecs/  to your repo list )


This setup has been tested on Centos 5.X with Puppet 2.6
We've successfully deployed a 2 node sipXecs setup from a 3rd puppetmaster


The keys are being  generated on the puppetmaster  by first 
Typically by including this on your puppetmaster : 



sipx::gensslreq{ "yourdomain": 
			platformdomainextension => "yourdomain.eu",
		 }

sipx::genssl{ "node-a":
			hostname   => "node-a.yourdomain.eu",
		}
sipx::genssl{ "node-b":
			hostname   => "node-b.yourdomain.eu",
		 }	

The above will setup the ca, and the keys for node-a and node-b 


On the sipXecs servers then you include the definition of your 
$sip_domain_aliases and your $sip_shared_secret 

On your primary SIP router you can : 

sipx::netconfig {
                "sipx":
                ipaddress => $ipaddres,
                netmask => $netmask,
        }




sipx::configserver{ "sipx": }
sipx::staticcertdbca{ "$hostname": }
sipx::staticcertdbnodes{ "$hostname": clientname => "node-a"; }
sipx::staticcertdbnodes{ "$hostname": clientname => "node-b"; }
sipx::supervisor { "$hostname": 
                        sipx_supervisor => "node-a.$platformdomainextension";
                } 
sipx::staticssl{ "$hostname": }


After deploying the device you need to go to the gui, set the password and configure the services you  need, 
If you add a second node as secondary sip router you also need to 
On the Secondary sip router you only need run puppet , it will register itselve on the primary node.
When using the sipx::register example as below  .. 



sipx::netconfig {
                "sipx":
                ipaddress => $ipaddress,
                netmask => $netmask;
        }


sipx::register{ 
	"$hostname": 
	clientname =>"node-b.${platformdomainextension}",
	password => "blah" ;}
sipx::supervisor { "$hostname": 
                        sipx_supervisor => "node-a.$platformdomainextension";
                } 
sipx::staticssl{ "$hostname": }








