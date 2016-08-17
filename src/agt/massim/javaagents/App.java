package massim.javaagents;

import java.io.IOException;

import eis.EILoader;
import eis.EnvironmentInterfaceStandard;
import eis.exceptions.ManagementException;

/**
 * This app instantiates an interpreter (loading agents),
 * creates the connection to the MASSim-server, and
 * executes the agents.
 *
 */
public class App {
    
	public static void main( String[] args ) {
		
		AgentsInterpreter interpreter = null;
		if ( args.length != 0 ) 
			interpreter = new AgentsInterpreter(args[0]);
		else
			interpreter = new AgentsInterpreter();

		// load the interface
		EnvironmentInterfaceStandard ei = null;
		
		try {
			ei = EILoader.fromClassName("massim.eismassim.EnvironmentInterface");
		} catch (IOException e) {
			e.printStackTrace();
			System.exit(0);
		}

		// start the interface
		try {
			ei.start();
		} catch (ManagementException e) {
			e.printStackTrace();
		}

		//  connect to environment
		interpreter.addEnvironment(ei);
				
		boolean running = true;
		while ( running ) {
			interpreter.step();
		}
	}
}
