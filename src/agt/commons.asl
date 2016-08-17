// Commons

/* --------- Percepts --------- */
 
+simStart
<-
!new_round; // começa uma nova rodada
.

+simEnd
<-
	!end_round; // termina a rodada atual
	!new_round; // começa a próxima rodada
.

+lastActionResult(R) : R \== none & R \== successful <- .print("last action result: ",R).
						
+pricedJob(JobId,Storage,Begin,End,Reward,Items) 
	: Reward > 0 & ja_estou_trabalhando(false)[source(vehicle4)]
		<- .print("Valor da recompensa ",Reward);
			//	se tiver os items, deliver_job
			//	senão ask for help		
 			//!help_complete_job(Items);
 			+necessario(Items);
 			-+ja_estou_trabalhando(true);
 			+entregar_em(JobId,Storage); 
.

// pede ajuda a outro agente para montar o bem
+help_me_assemble(Name)
<- !assist_assemble(Name).


+i_need_help_to_assemble(ToolId,Me,FacilityId) 
<- 	.my_name(Friend);
	.print("O agente ",Me," precisa da tool ",ToolId," e o agente ",Friend," vai ajudar.");
	!goto(FacilityId,0);
	!assist_assemble(Me);
	-i_need_help_to_assemble;
.

/* --------- Plans --------- */

// começa a rodada
+!new_round
<-  .print("-------------------- Entrou no Common-plans ----------------");	
	.

// termina a rodada
+!end_round
<-
	.print("-------------------- Fim da rodada ----------------");
	.abolish(_[source(self)]);
	.abolish(_[source(X)]);
    .drop_all_intentions;
    .drop_all_desires;	
.

// precisa montar um bem
+!need_to_assemble : is_need_to_assemble(ItemIdd,ToolId)
<- 	.print("Precisa fazer o item ",ItemIdd," com a tool ",ToolId);
	!goto(workshop1,0);
	?role(_,_,_,_,T);
	if(.member(ToolId,T)){
		.print("Eu tenho a ferramenta e vou fazer sozinho");
		!assemble(ItemIdd);			
	}else{	.print("Preciso de ajuda");
			.my_name(Me);
			?inFacility(FacilityId);
			.broadcast(tell,i_need_help_to_assemble(ToolId,Me,FacilityId));
	}
	?item(ItemIdd,Amount);		
	!give(veihcle4,ItemIdd,Amount);
	+plays(initiator,vehicle4);
	+item_dado;
.

// atualiza a localização atual do agente
+!update_location(Ag,L)
<-   -ag_loc(Ag,_);
     +ag_loc(Ag,L);
.

+!all_at(Ags,Loc) : .count(.member(A,Ags) & ag_loc(A,Loc)) == .length(Ags).
+!all_at(Ags,Loc) 
<-  .findall(A, .member(A,Ags) & ag_loc(A,Loc),LAt);
    .difference(Ags,LAt,RAgs);
    ?step(S);
    .print("waiting ",RAgs," to arrive at ",Loc," -- step ",S);
    !skip;
    !all_at(Ags,Loc);
.

// espera por alguma crença
+!wait_skip(B) : B.
+!wait_skip(B) <- !skip; !wait_skip(B).

+!skip_forever
<- !skip;
   !skip_forever;
.

// compra um item com base na quantidade
+!buy_item(Item,Amount) : item(Item,A) & A < Amount.

+!buy_item(Item,Amount) : load(C) & C == 0 
<-  ?find_shop(Item,S);
    !goto(S, 0);
    .print("ok, at ",S);
    !buy(Item,Amount);
    +item(Item,Amount);
    !buy_item(Item,Amount).
    
+!buy_item(Item,Amount) : item(Item,A) & A == Amount
<- 	.print("Entered in assemble verification");  
	!need_to_assemble;
.
    
/* --------- Beliefs and Rules --------- */

// busca um shop com base no id do item necessário
find_shop(ItemId, ShopId) 	:- shop(ShopId,_,_,Items) &	.member(item(ItemId,Price,Amount,_),Items).

// verifica se precisa recarregar com base na quantidade atual de bateria	
precisa_recarregar 			:- role(R,_,_,BC,_) & charge(C) & C <= BC/3.

/* required_tool(T) :-
   role(_,_,_,_,Tools) & 
   .member(T,Tools) &
   not item(T,_)
  .
  * 
  */