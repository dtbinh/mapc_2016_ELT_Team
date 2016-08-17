package util;

import jacamo.infra.JaCaMoLauncher;
import jason.JasonException;
import massim.javaagents.App;
import massim.javaagents.city.utils.SimpleDebugStreamAgent;

public class StartTeams {

	public static void main(String[] args) throws JasonException {

		// starts a simple team of Java Agents
		new Thread(new Runnable() {
			@Override
			public void run() {
				SimpleDebugStreamAgent.actionconfformat = "conf/team-b/actionconf/";
				App.main(new String[] { "./conf/teste/javaagentsconfig.xml" });
			}
		}).start();
		
		// starts the JaCaMo team
		JaCaMoLauncher.main(new String [] { "mapc_elt_2016.jcm" } );
	}
}
