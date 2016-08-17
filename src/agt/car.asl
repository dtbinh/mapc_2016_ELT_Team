// Agente Car 

/* Initial beliefs and rules */

plays(initiator,vehicle4).  										// começa um novo leilão
is_battery_over				:- ask_extra_charge. 					// verifica se a bateria acabou
is_need_to_charge			:- go_charge_battery.					// verifica se precisa recarregar
is_auction_open             :- auctionJob(JobId,_,_,_,_,MaxBid,_,_).// verifica se existe leilão aberto
is_any_cfp					:- cfp(Id,Objeto).           	 		// verifica se existe algum cfp
price(Task,Offer).												    // verifica o valor da oferta
 
/* --------- Car Goals --------- */

!start_car_goal.

+!start_car_goal
	<-	
		.print("Starting car goal ...");			
.

/* --------- Car Plans --------- */

@ask_extra_charge[atomic]
	+charge(C) : C == 0 
		<- 	.print("Battery is over!");
				!call_breakdown_service
.

/* --------- Drone Percepts --------- */

// envia uma mensagem para o leiloeiro se apresentando como um participante
+plays(initiator,vehicle4)
	: .my_name(Me)
	<- 	.send(vehicle4,tell,introduction(participant,Me)).
	
	// responde a chamada para dar um lance
	@c1 +cfp(CNPId,Task,Quantidade,Vol)[source(A)]
		: plays(initiator,A) & price(Task,Offer)
		<- 	?role(_,_,Volume,_,Tool);
			if (Vol <= Volume){
				+price(Task,Volume);
			} else {+price(Task,1200);}
			?price(Task,Offer);
			+proposal(CNPId,Task,Quantidade,Offer); // relembra a minha proposta
			.send(A,tell,propose(CNPId,Offer)).
			
	// a minha proposta foi aceita		
	@r1_1 +accept_proposal(CNPId)
		: proposal(CNPId,Task,Quantidade,Offer)
		<-	.print("My proposal: ",Offer," won CNP ",CNPId," for ",Task,"!"," with quantity",Quantidade);
			-plays(initiator,vehicle4);
			.print("removi o plays");
			.print("Vou comprar o item ",Task," com quantidade ",Quantidade);
			!buy_item(Task,Quantidade).
			
	// faz a atividade e envia o relatório para o leiloeiro
	@r2_1 +reject_proposal(CNPId)
		<-	.print("I lost CNP ",CNPId, ".");
			-proposal(CNPId,_,_)
.
