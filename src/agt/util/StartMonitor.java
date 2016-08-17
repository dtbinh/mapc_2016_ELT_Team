package util;

import massim.competition2015.monitor.GraphMonitor;
import massim.test.InvalidConfigurationException;

public class StartMonitor {

	public static void main(String[] args) throws InvalidConfigurationException {

		GraphMonitor.main(new String[] { "-rmihost", "localhost", "-rmiport", "1099" });
		
	}
}
