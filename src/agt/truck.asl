// Agente Truck

/* Initial beliefs and rules */

ja_estou_trabalhando(false).  					  // verifica se o agente já está executando um trabalho
cnp_Id(0).									      // id inicial do cnp	
is_battery_over				:- ask_extra_charge.  // verifica se a bateria acabou
is_need_to_charge			:- go_charge_battery. // verifica se precisa recarregar

/* --------- Truck Goals --------- */

!start_truck_goal.

+!start_truck_goal
	<-	
		.print("Starting truck goal ...");					
.

/* --------- Truck Plans --------- */

+!start_CNP(Id,Objeto,Quantidade,Volume)
	<-	.wait(2000); // wait participants introduction
		+cnp_state(Id,propose); // remember the state of the CNP
		.findall(Name,introduction(participant,Name),LP);
		.print("Sending CFP to ",LP," from ID ",Id);
		.send(LP,tell,cfp(Id,Objeto,Quantidade,Volume));
		.concat("+!contract(",Id,")",Event);
		// the deadline of the CNP is now + 4 seconds, so
		// the event +!contract(Id) is generated at that time
		.at("now +4 seconds", Event).
		
// receive proposal
// if all proposal have been received, don't wait for the deadline
@r1 +propose(CNPId,Offer) //r1 e r2 checa as propostas e refuses enquanto o propose ainda est� aberto
	: cnp_state(CNPId,propose) & all_proposals_received(CNPId)
<- 	!contract(CNPId).

// receive refusals
@r2 +refuse(CNPId)
	: cnp_state(CNPId,propose) & all_proposals_received(CNPId)
<- 	!contract(CNPId).

// this plan needs to be atomic so as not to accept
// proposals or refusals while contracting
@lc1[atomic]
+!contract(CNPId)
	: cnp_state(CNPId,propose)
<- 	-+cnp_state(CNPId,contract);
	.findall(offer(X,A),propose(CNPId,X)[source(A)],L);
	.print("Offers are ",L);
	L \== []; // constraint the plan execution to at least one offer
	.min(L,offer(WOf,WAg)); // sort offers, the first is the best
	.print("Winner is ",WAg," with ",WOf);
	!announce_result(CNPId,L,WAg);
	-+cnp_state(Id,finished);
	?preciso(item(ItemId,Q));
	.send(WAg,tell,preciso(item(ItemId,Q)));
	?is_need_to_assemble(ItemIdd,ToolId);
	.send(WAg,tell,is_need_to_assemble(ItemIdd,ToolId));	
	.              
// nothing todo, the current phase is not �propose�
@lc2 +!contract(CNPId).
	-!contract(CNPId)
<- 	.print("CNP ",CNPId," has failed!").
	+!announce_result(_,[],_).
	
// announce to the winner
+!announce_result(CNPId,[offer(O,WAg)|T],WAg)
<- 	.send(WAg,tell,accept_proposal(CNPId));
	!announce_result(CNPId,T,WAg);
.
	
// announce to others
+!announce_result(CNPId,[offer(O,LAg)|T],WAg)
<- 	.send(LAg,tell,reject_proposal(CNPId));
	!announce_result(CNPId,T,WAg).

@ask_extra_charge[atomic]
	+charge(C) : C == 0 
		<- 	.print("Battery is over!");
				!call_breakdown_service
.

/* --------- Drone Percepts --------- */

// itens necessários para compor o job
+necessario(Items)
	<-	for(.member(X,Items)){
			.print(X);
			+preciso(X);			
	}	
.

// itens que faltam para compor o job
+preciso(item(ItemId,Q))
<- .print("O id  ",ItemId," A quantidade ",Q);
	?product(ItemId,Volume,Item_name);
	for(.member(consumed(IdBuy,VolBuy),Item_name)){
		.print("Precisa comprar ",IdBuy," a quantidade ",VolBuy," e ele pesa ",Volume);
		.print("Vou comprar ",IdBuy," a quantidade ",VolBuy*Q," e ele pesa ",Volume*Q*VolBuy);
		if(.member(tools(ToolId,ToolQ),Item_name) & ToolId \== []){
		.print("Precisa Manufaturar o produto",ItemId," ele usa ",ToolQ," ferramenta ",ToolId);
		+is_need_to_assemble(ItemId,ToolId);
		}else{!buy_item(IdBuy,VolBuy*Q);}
		?cnp_Id(Id);
		!start_CNP(Id,IdBuy,VolBuy*Q,Volume*Q*VolBuy);
		.print("Começou o CNP ",Id," para ",IdBuy);
		.wait(5000);  		
  		-+cnp_Id(Id + 1);  			
		}
.

// job do tipo auction
+auctionJob(JobId,_,Abertura,Fechamento,Fine,MaxBid,Items)	: ja_estou_trabalhando(false) & Fechamento - Abertura > 180 & Fine <= 10000
	<-	-ja_estou_trabalhando(false); 	
		.print("Doing a bid in an auction for a new job ",JobId,MaxBid," Os itens necessarios sao",Items);
		!bid_for_job(JobId,MaxBid*0.6);
.

// job que foi conseguido
+jobTaken(JobId)
	<- ?auctionJob(JobId,Storage,_,_,_,_,Items); 
		.print("Ganhei o leilao para os itens ",Items);
		+necessario(Items);
		-+ja_estou_trabalhando(true);
		+entregar_em(JobId,Storage);	
.

// entrega do job no local indicado
+entregar_em(JobId,Storage)
	<- 	!goto(Storage,0);
		!deliver_job(JobId);
		-+ja_estou_trabalhando(false);	
.

// item fornecido por outro agente	 
+item_dado : true
	<- !receive;
.