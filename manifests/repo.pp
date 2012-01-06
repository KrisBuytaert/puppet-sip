class sipx::repo {
	
	file {
		"/etc/yum.repos.d/sipx.repo":
			source => "puppet:///modules/sipx/sipxecs-4.2.1-centos.repo",
	}


}

