package environment;

import jason.JasonException;
import jason.NoValueException;
import jason.asSyntax.Literal;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.logging.Logger;

import cartago.AgentId;
import cartago.Artifact;
import cartago.INTERNAL_OPERATION;
import cartago.OPERATION;
import cartago.ObsProperty;
import eis.EILoader;
import eis.EnvironmentInterfaceStandard;
import eis.exceptions.ActException;
import eis.exceptions.AgentException;
import eis.exceptions.EntityException;
import eis.exceptions.ManagementException;
import eis.exceptions.NoEnvironmentException;
import eis.exceptions.PerceiveException;
import eis.exceptions.RelationException;
import eis.iilang.Action;
import eis.iilang.EnvironmentState;
import eis.iilang.Parameter;
import eis.iilang.Percept;

public class EISArtifact extends Artifact {

	private Logger logger = null;

	private EnvironmentInterfaceStandard ei;
	private Map<String, AgentId> agentIds;
	private Map<String, String> agentToEntity;

	private boolean receiving;

	public EISArtifact() throws IOException {
		agentIds      = new ConcurrentHashMap<String, AgentId>();
		agentToEntity = new ConcurrentHashMap<String, String>();

		try {
			ei = EILoader.fromClassName("massim.eismassim.EnvironmentInterface");
			if (ei.isInitSupported())
				ei.init(new HashMap<String, Parameter>());
			if (ei.getState() != EnvironmentState.PAUSED)
				ei.pause();
			if (ei.isStartSupported())
				ei.start();
		} catch (IOException | ManagementException e) {
			e.printStackTrace();
		}
	}

	protected void init() throws IOException {
		receiving = true;
		execInternalOp("receiving");
	}

	@OPERATION
	void register() throws EntityException {
		try {
			String agent = getOpUserId().getAgentName();
			ei.registerAgent(agent);
			ei.associateEntity(agent, agent);
			agentToEntity.put(agent, agent);
			agentIds.put(agent, getOpUserId());
			logger = Logger.getLogger(EISArtifact.class.getName());
			logger.info("Registering: " + agent);
		} catch (AgentException e) {
			e.printStackTrace();
		} catch (RelationException e) {
			e.printStackTrace();
		}
	}

	@OPERATION
	void registerEISEntity(String entity) throws EntityException {
		try {
			String agent = getOpUserId().getAgentName();
			ei.registerAgent(agent);
			ei.associateEntity(agent, entity);
			agentToEntity.put(agent, entity);
			agentIds.put(agent, getOpUserId());
			logger = Logger.getLogger(EISArtifact.class.getName()+"_"+agent);
			logger.info("Registering " + agent + " to entity " + entity);
		} catch (AgentException e) {
			e.printStackTrace();
		} catch (RelationException e) {
			e.printStackTrace();
		}
	}

	@OPERATION
	void registerFreeconn() throws EntityException {
		try {
			String agent = getOpUserId().getAgentName();
			ei.registerAgent(agent);
			String entity = ei.getFreeEntities().iterator().next();
			ei.associateEntity(agent, entity);
			agentToEntity.put(agent, entity);
			agentIds.put(agent, getOpUserId());
			logger = Logger.getLogger(EISArtifact.class.getName());
			logger.info("Registering " + agent + " to entity " + entity);
		} catch (AgentException e) {
			e.printStackTrace();
		} catch (RelationException e) {
			e.printStackTrace();
		}
	}

	@OPERATION
	public void action(String action) throws NoValueException {
		try {
			Action a = Translator.literalToAction(action);
			String agent = getOpUserName();
			ei.performAction(agent, a, agentToEntity.get(agent));
			//logger.info("Agent "+agent+" did "+action);
		} catch (ActException e) {
			e.printStackTrace();
		}
	}

	@INTERNAL_OPERATION
	void receiving() throws JasonException {
		int lastStep = -1;
		Collection<Percept> previousPercepts = new ArrayList<Percept>();

		while (receiving) {
			await_time(100);
			for (String agent: agentIds.keySet()) {
				try {
					Collection<Percept> percepts = ei.getAllPercepts(agent).get(agentToEntity.get(agent));
					//logger.info("***"+percepts);
					if (percepts.isEmpty())
						break;
					int currentStep = getCurrentStep(percepts);
					if (lastStep != currentStep) { // only updates if it is a new step
						lastStep = currentStep;
						//logger.info("new step "+currentStep);
						udpatePerception(agent, previousPercepts, percepts);
						previousPercepts = percepts;
					}
				} catch (PerceiveException | NoEnvironmentException e) {
					e.printStackTrace();
				}
			}
		}
	}
	
	private int getCurrentStep(Collection<Percept> percepts) {
		for (Percept percept : percepts) {
			if (percept.getName().equals("step")) {
				//logger.info(percept+" "+percept.getParameters().getFirst());
				return new Integer(percept.getParameters().getFirst().toString());
			}
		}
		return -10;
	}	

	private void udpatePerception(String agent, Collection<Percept> previousPercepts, Collection<Percept> percepts) throws JasonException {
		
		// compute removed perception
		for (Percept old: previousPercepts) {
			if (step_obs_prop.contains(old.getName())) {
				if (!percepts.contains(old)) { // not perceived anymore
					Literal literal = Translator.perceptToLiteral(old);
					removeObsPropertyByTemplate(old.getName(), (Object[]) literal.getTermsArray());
					//logger.info("removing old perception "+literal);
				}
			}
		}
		
		// compute new perception
		Literal step = null;
		for (Percept percept: percepts) {
			if (step_obs_prop.contains(percept.getName())) {
				if (!previousPercepts.contains(percept)) { // really new perception 
					Literal literal = Translator.perceptToLiteral(percept);
					if (percept.getName().equals("step")) {
						step = literal;
					} else if (percept.getName().equals("simEnd")) {
						cleanObsProps(step_obs_prop);
						cleanObsProps(match_obs_prop);
						defineObsProperty(percept.getName(), (Object[]) literal.getTermsArray());
						break;
					} else {
						//logger.info("adding "+literal);
						defineObsProperty(percept.getName(), (Object[]) literal.getTermsArray());
					}
				}
			} else if (match_obs_prop.contains(percept.getName())) {
				Literal literal = Translator.perceptToLiteral(percept);
				//logger.info("adding "+literal);
				defineObsProperty(literal.getFunctor(), (Object[]) literal.getTermsArray());				
			}
		}
		
		/*
		cleanObsProps(step_obs_prop);
		Literal step = null;
		for (Percept percept : percepts) {
			if (step_obs_prop.contains(percept.getName()) || match_obs_prop.contains(percept.getName())) {
				Literal literal = Translator.perceptToLiteral(percept);
				if (literal.getFunctor().equals("step")) {
					step = literal;
				} else if (literal.getFunctor().equals("simEnd")) {
					cleanObsProps(step_obs_prop);
					cleanObsProps(match_obs_prop);
					defineObsProperty(literal.getFunctor(), (Object[]) literal.getTermsArray());
					break;
				} else {
					logger.info("adding "+literal);
					defineObsProperty(literal.getFunctor(), (Object[]) literal.getTermsArray());
				}
			}
		}
		*/
		
		if (step != null) {
			//logger.info("adding "+step);
			//signal(agentIds.get(agent), step.getFunctor(), (Object[]) step.getTermsArray());
			defineObsProperty(step.getFunctor(), (Object[]) step.getTermsArray());
		}

	}

	private void cleanObsProps(Set<String> obSet) {
		for (String obs: obSet) {
			cleanObsProp(obs);
		}
	}

	private void cleanObsProp(String obs) {
		try {
			ObsProperty ob = getObsProperty(obs);
			while (ob != null) {
				//logger.info("Removing "+ob);
				removeObsProperty(obs);
				ob = getObsProperty(obs);
			}
		} catch (Exception e) {
			// ignore
		}
	}

	@OPERATION
	void stopReceiving() {
		receiving = false;
	}

	static Set<String> match_obs_prop = new HashSet<String>( Arrays.asList(new String[] {
		"steps",
		"product",
		"role",
	}));
	
	static Set<String> step_obs_prop = new HashSet<String>( Arrays.asList(new String[] {
			"auctionJob",
			"bye",
			"charge",
			"chargingStation",
			"deadline",
			"dump",
			"entity",
			"fPosition",
			"id",
			"inFacility",
			"item",
			"jobPosted",
			"jobTaken",
			"lat",
			"load",
			"lon",
			"lastAction",
			"lastActionParam",
			"lastActionResult",
			"map",
			"money",
			"pricedJob",
			"product",
			"ranking",
			"requestAction",
			"role",
			"route",
			"routeLength",
			"seedCapital",
			"shop",
			"simEnd",
			"simStart",
			"step",
			"steps",
			"storage",
			"timestamp",
			"workshop",
			"visibleChargingStation"			
			
	}));

}