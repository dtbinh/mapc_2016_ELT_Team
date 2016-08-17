// Agente Motorcycle

/* Initial beliefs and rules */

plays						(initiator,vehicle4). // inicio do leilão
is_not_job_open				(false). 			  // verifica se existe um job aberto
price						(Task,Offer).		  // verifica o valor da oferta
is_battery_over				:- ask_extra_charge.  // verifica se a bateria acabou
is_need_to_charge			:- go_charge_battery. // verifica se precisa carregar a bateria

/* --------- Motorcycle Goals --------- */

!start_motorcycle_goal.

+!start_motorcycle_goal
	<-	
		.print("Starting motorcycle goal ...");
			!wait_skip(B);
				!select_motorcycle_goal
.

+!select_motorcycle_goal  
	:   is_not_job_open(false)
		<- 	.print("Openning a new priced job opportunity");
				!post_job_priced(math.round(math.random(10) * 100), math.round(math.random(10) * 10), storage1, .list(item(base1,math.round(math.random * 10)), item(base2,math.round(math.random * 10)), item(base3,math.round(math.random * 10))));
					-+is_not_job_open(true);
						!!select_motorcycle_goal
.

/* --------- Motorcycle Plans --------- */

@ask_extra_charge[atomic]
	+charge(C) : C == 0 
		<- 	.print("Battery is over!");
				!call_breakdown_service
.

/* --------- Motorcycle Percepts --------- */

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
			+proposal(CNPId,Task,Quantidade,Offer); // relembre a minha proposta
			.send(A,tell,propose(CNPId,Offer)).
	
	// a minha proposta foi aceita
	@r1_1 +accept_proposal(CNPId)
		: proposal(CNPId,Task,Quantidade,Offer)
		<-	.print("My proposal: ",Offer," won CNP ",CNPId," for ",Task,"!"," with quantity",Quantidade);
			-plays(initiator,vehicle4);
			.print("removi o plays");
			.print("Vou comprar o item ",Task," com quantidade ",Quantidade);
			!buy_item(Task,Quantidade);
			.
	// faz a atividade e envia o relatório para o leiloeiro
	@r2_1 +reject_proposal(CNPId)
		<-	.print("I lost CNP ",CNPId, ".");
			-proposal(CNPId,_,_)
.	
