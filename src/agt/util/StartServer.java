package util;

import massim.server.Server;
import massim.test.InvalidConfigurationException;

public class StartServer {

	public static void main(String[] args) throws InvalidConfigurationException {
		Server.main(new String[] { "--conf", "conf/test-completescenario/2015-complete-3sims.xml" });
	}

}
