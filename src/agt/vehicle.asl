// Abstração Vehicle

{ include("commons.asl") }
{ include("actions.asl") }

// register this agent into the MAPC server (simulator) using a personal interface artifact
+!register_EIS(E)
<-  
    .my_name(Me);
    .concat("perso_art_",Me,AName);
    makeArtifact(AName,"environment.EISArtifact",[],AId);
    focus(AId);
    registerEISEntity(E);
. 

+!register_freeconn
<-	
    .print("Registering...");
	registerFreeconn;
.

// plan to react to the signal role/5 (from EISArtifact)
// it loads the source code for the agent's role in the simulation
+role(Role, Speed, LoadCap, BatteryCap, Tools)
<-
	.print("Got role: ", Role);	
	.lower_case(Role, File);
	.concat(File, ".asl", FileExt);
	.include(FileExt);
.

