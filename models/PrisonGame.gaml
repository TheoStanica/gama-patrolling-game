/**
* Name: PrisonPatrollingGame
* Based on the internal empty template. 
* Author: teo_t
* Tags: 
*/


model PrisonPatrollingGame

global {
	int env_length <- 200;
	
	int nb_obstacles <- 15 parameter: true;
	int nb_coinboxes <- 20 parameter: true min:0 max: 50;
	int max_coins_in_coinbox <- 5 parameter: true min: 1 max: 10;
	
	int nb_workers <- 5 parameter:true;
	float worker_trust_treshold <- 0.4 parameter: true min: 0.0 max: 1.0;
	float worker_proximity_radius <- 10.0 parameter: true;
	float worker_socializing_radius <- 15.0 parameter: true;
	float worker_max_energy <- 5.0;
	float worker_strength <- 4.0;
	
	int fine_amount <- 2;
	
	int nb_guardians <- 0;
	float guardian_perception_distance <- 30.0;
	float guardian_speed <- 1.0;
	float guardian_fov <- 60.0;
	float maximum_distance_between_self_and_target_to_chase <- 100.0;
	float guard_proximity_radius <- 10.0;
	float guardian_max_energy <- 7.0;
	float guardian_strength <- 3.0;
	
	int nb_lazy_guardians <- 0;
	float lazy_guardian_speed_percent_bonus <- -50.0;
	float lazy_guardian_perception_distance_percent_bonus <- 45.0;
	float lazy_guardian_fov <- 110.0;
	float lazy_guardian_strength <- 1.0;
	
	int nb_fast_guardians <- 4;
	float fast_guardian_speed_percent_bonus <- 40.0;
	float fast_guardian_perception_distance_percent_bonus <- 20.0;
	float fast_guardian_fov <- 30.0;
	float fast_guardian_strength <- 2.0;
	
	
	
	
	int coins_required_to_escape <- 30;
	Safezone the_safezone;
	
	
	string coinbox_at_location <- "coinbox_at_location";
	string empty_coinbox_location <- "empty_coinbox_location";
	
	predicate coinbox_location <- new_predicate(coinbox_at_location);
	predicate choose_coinbox <- new_predicate("choose a coinbox");
	
	predicate get_coins <- new_predicate("get coins");
	predicate has_coin_in_hand <- new_predicate("has coin in hand");
	predicate find_coins <- new_predicate("find coins");
	predicate store_coins <- new_predicate("store coins");
	predicate share_coinbox_information <- new_predicate("share coinbox information");
	
	predicate patrol <- new_predicate("patrol");
	predicate chase_worker <- new_predicate("chase worker");
	predicate misbehaving_worker <- new_predicate('misbehaving worker');
	predicate share_info_about_misbehaving_worker <- new_predicate('share info about misbehaving worker');
	
	predicate stay_stunned <- new_predicate("stay_stunned");
	predicate is_stunned <- new_predicate("is_stunned");
	
	
	
	
	
	
	int precision <- 600 parameter: true;
	
	geometry shape <- square(env_length);
	geometry obstacle_space <- nil;
	geometry free_space <- copy(shape);
	geometry free_space_without_safezones <- copy(free_space);
	init {		
		loop times: nb_obstacles {
			create obstacle {
				location <- any_location_in(free_space);
				shape <- circle(2+rnd(15));
				free_space <- free_space - shape;
				free_space_without_safezones <- free_space_without_safezones - shape;
				obstacle_space <- obstacle_space + shape;
			}
		}
		create Safezone number: 1 {
			location <- any_location_in(free_space);
			free_space_without_safezones <- free_space_without_safezones - shape;
			the_safezone <- self;
		}
		create CoinBox number: nb_coinboxes{
			location <- any_location_in(free_space_without_safezones);
		}
		create BaseGuardian number: nb_guardians  {
			location <- any_location_in(free_space);
		}
		create LazyGuardian number: nb_lazy_guardians {
			location <- any_location_in(free_space);
		}
		create FastGuardian number: nb_fast_guardians {
			location <- any_location_in(free_space);
		}	
		create Worker number: nb_workers {
			location <- any_location_in(free_space);
		}
	}
	
	reflex display_social_links when: every(10#cycle){
        loop tempMiner over: Worker{
        	loop tempDestination over: tempMiner.social_link_base{
            	if (tempDestination !=nil){
                	bool exists<-false;
                    loop tempLink over: socialLinkRepresentation{
                    	if((tempLink.origin=tempMiner) and (tempLink.destination=tempDestination.agent)){
                    		exists<-true;
                    	}
              		}
                	if(not exists){
                		create socialLinkRepresentation number: 1{
                    		origin <- tempMiner;
                        	destination <- tempDestination.agent;
                        	if(get_trust(tempDestination)> worker_trust_treshold){
                        		my_color <- #green;
                        	} else {
                        		my_color <- #red;
                        	}
                    	}
                	}
            	}
         	}
    	}
    }
}

species obstacle {
	aspect default {
		draw shape color: #gray ;
		
	}
}

species BaseAgent skills: [moving] control: simple_bdi{
	float perception_distance <- guardian_perception_distance;
	float fov <- guardian_fov;
	float speed <- guardian_speed;
	rgb my_color <- rnd_color(255);
	rgb chart_color <- rnd_color(255);
	bool stunned <- false;
	int stunned_cycles <- 0;
	
	
	
	geometry perceived_area;
	point target ;
	
	rule belief:is_stunned new_desire: stay_stunned strength: 5.0;
	
	action goToPlace(point goTo){
		do goto target: goTo.location ;
		if not(self overlaps free_space ) {
			location <- ((location closest_points_with free_space)[1]);
		}
	}
	
	action moving_around{
		if (target = nil ) {
			if (perceived_area = nil) or (perceived_area.area < 2.0) {
				do wander bounds: free_space;
			} else {
				target <- any_location_in(perceived_area);
			}
		} else {
			do goto target: target;
			if (location = target)  {
				target <- nil;
			}
		}
	}
	
	action stunned(int seconds) {
		write name + " i am doing stunned action";
		stunned <- true;
		do add_belief(is_stunned);
	}
	
	plan stay intention: stay_stunned  when: every(1#cycle) {
		if(stunned_cycles <= 100){
			stunned_cycles <- stunned_cycles + 1;
		} else {
			write "finish";
			stunned <- false;
			stunned_cycles <- 0;
			do remove_belief(is_stunned);
			do remove_intention(stay_stunned,true);	
		}
	}
	
	reflex update_perception when: every(1#cycle) {
		perceived_area <- (cone(heading-fov/2,heading+fov/2) intersection world.shape) intersection circle(perception_distance); 
		if (perceived_area != nil) {
			perceived_area <- perceived_area masked_by(obstacle);
		}
	}
	
	aspect body {
		draw circle(1) color: my_color;
	}
	
	aspect perception {
		if (perceived_area != nil) {
			draw perceived_area color: my_color;
			draw circle(1) at: target color: #pink;
		}
	}
}

species BaseGuardian parent:BaseAgent {
	float perception_distance <- guardian_perception_distance;
	float base_speed <- guardian_speed;
	float speed <- guardian_speed;
	float energy <- 1.0;
	float max_energy <- guardian_max_energy;
	float fov <- guardian_fov;
	rgb my_color <- #blue;
	Worker worker_perceived <- nil;
	float guard_proximity_rad <- guard_proximity_radius;
	int fine <- fine_amount;
	float strength <- guardian_strength;
	
	
	Worker worker_to_chase <- nil;
	
	rule belief:misbehaving_worker new_desire:chase_worker strength: 2.0;
	
	
	init {
		do add_desire(patrol, 1.0);
	}
	
	plan patrolling intention: patrol{
		do moving_around;
	}
	
	reflex update when: energy < max_energy {
		energy <- energy + 0.015;  // +1 energy every 67 steps 			
	}
	
	perceive target: agents of_generic_species BaseGuardian  in: free_space{
		socialize;
	}
	
	perceive target:Worker in: union([perceived_area,circle(guard_proximity_rad)]){
		if(myself.perceived_area != nil){ 
			myself.worker_to_chase <- self;
			if( self.has_belief(has_coin_in_hand)){
				ask myself{
					do decideToChase;
				}
			}
		}
	}
	
	action decideToChase{
		do remove_intention(patrol, false);
		do add_belief(misbehaving_worker);
		do add_desire(predicate: share_info_about_misbehaving_worker, strength: 5.0);
	}
	
	plan tell_guardians_about_misbehaving_worker intention: share_info_about_misbehaving_worker instantaneous: true{
		if(self.worker_to_chase != nil){
			list<BaseAgent> all_guardians <- list<BaseAgent>((social_link_base where (each.agent distance_to self.worker_to_chase < maximum_distance_between_self_and_target_to_chase)) collect each.agent);
			Worker chase <- self.worker_to_chase;
			ask all_guardians{
				do remove_intention(patrol, false);
				do add_belief(misbehaving_worker);
				myself.worker_to_chase <- chase;
			}
		}
		do remove_intention(share_info_about_misbehaving_worker, true);
	}
	
	plan chaseWorker intention: chase_worker {
		if(self.worker_to_chase != nil and self.worker_to_chase.has_belief(has_coin_in_hand)){	
			do goToPlace goTo: self.worker_to_chase.location;
			if(energy > 0.0){
				speed <- base_speed + base_speed * (energy * 0.07);    //  49.5% max bonus speed
				energy <- energy - 0.02;			
			}
			if(self.location = self.worker_to_chase.location ){	
				do attack_worker;
				self.worker_to_chase <- nil;
			}
		} else {
			do remove_intention(chase_worker, true);
			do add_intention(patrol);
			self.speed <- base_speed;
		}
	}

	action attack_worker {
		float my_attack_score <- energy + strength + base_speed;
		int my_RNG <- rnd(-25,25);
		my_attack_score <- my_attack_score + (abs(my_attack_score ) * my_RNG)/100.0;
		
		Worker worker <- worker_to_chase;
		float worker_attack_score <- worker.energy + worker.strength + worker.base_speed;
		int worker_RNG <- rnd(-25,25);
		worker_attack_score <- worker_attack_score + (abs(worker_attack_score ) * worker_RNG)/100.0;
		
		write "My attack score is: " + my_attack_score + " worker sore: " + worker_attack_score;
		float difference <- my_attack_score - worker_attack_score;
		
		if(difference >= 0){
			write "GUARDIAN WINS THE FIGHT";
			ask worker_to_chase{
				coins_in_hand <- 0;
				do remove_belief(has_coin_in_hand);
				coins_safe <- coins_safe - myself.fine;		
				do stunned(5);		
			}
		} else {
			write "WORKER WINS THE FIGHT AND GETS AWAY";
			// rng to find a coin in guardian's pockets
			ask self {
				do stunned(5);
			}
		}
	}
	
	aspect proximity_radius {
		draw circle(guard_proximity_rad) color:#gray empty: true;
	}
}

species LazyGuardian parent:BaseGuardian {
	float base_speed <- guardian_speed + (lazy_guardian_speed_percent_bonus * abs(guardian_speed))/100.0;
	float perception_distance <-guardian_perception_distance + (lazy_guardian_perception_distance_percent_bonus * abs(guardian_perception_distance))/100.0;
	float fov <- lazy_guardian_fov;
	float strength <- lazy_guardian_strength;
}

species FastGuardian parent: BaseGuardian {
	float base_speed <- guardian_speed + (fast_guardian_speed_percent_bonus * abs(guardian_speed))/100.0;
	float perception_distance <-guardian_perception_distance + (fast_guardian_perception_distance_percent_bonus * abs(guardian_perception_distance))/100.0;
	float fov <- fast_guardian_fov;
	float strength <- fast_guardian_strength;
}

species Worker parent: BaseAgent {
	int coins_needed_to_escape <- coins_required_to_escape;
	float energy <- 1.0;
	float base_speed <- 1.0;
	float max_energy <- worker_max_energy;
	Worker worker_perceived <- nil;
	int coins_in_hand <- 0;
	int coins_safe <- 0;
	rgb my_color <- #red;
	float worker_proximity_rad <- worker_proximity_radius;
	float worker_socializing_rad <- worker_socializing_radius;
	float strength <- worker_strength;
	
	
	bool use_social_architecture <- true;
	bool use_emotions_architecture <- true;

	rule belief: coinbox_location new_desire: get_coins strength: 2.0;
	rule belief: has_coin_in_hand new_desire: store_coins strength: 3.0;	
	
	init{
		do add_desire(find_coins, 1.0);
	}
	
	reflex update when: energy < max_energy {
		energy <- energy + 0.015;  // +1 energy every 67 steps 			
	}
	
	perceive target: agents of_generic_species BaseGuardian in:worker_proximity_rad  when: has_belief(has_coin_in_hand) {
		if(myself.energy > 0.0){
			myself.speed <- myself.base_speed + myself.base_speed*(myself.energy * 0.07);    //  35% max bonus speed
			myself.energy <- myself.energy - 0.02;		
		} 
	}	
	
	perceive target: CoinBox in:perceived_area when: every(1#cycle){
		if(myself.perceived_area != nil){
			focus id: coinbox_at_location var: location;
			ask myself{
				do add_desire(predicate: share_coinbox_information, strength: 5.0);
				do remove_intention(find_coins, false);
			}
		}
	}
	
	perceive target: Worker in: worker_socializing_rad {
		if(self != myself){
			myself.worker_perceived <- self;
			socialize liking:0.1;
			do change_trust(worker_perceived, 0.009);	
		}
	}
	
	plan finding_coins intention: find_coins   {
		do moving_around;
	}
	
	plan getting_coins intention: get_coins{
		if(target = nil){
			do add_subintention(get_current_intention(), choose_coinbox, true);
			do current_intention_on_hold();
		} else {
			do goToPlace goTo: target.location;
			if(target = location){
				CoinBox current_box <- CoinBox first_with(target = each.location);
				if (current_box != nil) {
					ask current_box {
						coins <- coins - 1;
					}
					ask self {
						coins_in_hand <- coins_in_hand + 1;
					}
					do add_belief(has_coin_in_hand);
					do remove_intention(get_coins, true);			
				} else {
					do add_belief(new_predicate(empty_coinbox_location, ["location_value"::target]));
					do remove_belief(new_predicate(coinbox_at_location, ["location_value"::target]));
				}
				target <- nil;
			}
		}
	}
	
	plan choose_closest_coinbox intention: choose_coinbox instantaneous: true{
		list<point> possible_coinboxes <- get_beliefs_with_name(coinbox_at_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		list<point> empty_coinboxes <- get_beliefs_with_name(empty_coinbox_location) collect (point(get_predicate(mental_state (each)).values["location_value"]));
		possible_coinboxes <- possible_coinboxes - empty_coinboxes;
		if(empty(possible_coinboxes)){
			do remove_intention(get_coins, true);
		} else {
			target <- (possible_coinboxes with_min_of(each distance_to self)).location;	
		}
		do remove_intention(choose_coinbox, true);
	}
	
	plan store_coin_at_safezone intention: store_coins{
		do goToPlace goTo: the_safezone.location;
		if(has_belief(has_coin_in_hand)){
			if(the_safezone.location = location){
				do remove_belief(has_coin_in_hand);
				do remove_intention(store_coins, true);
				coins_safe <- coins_safe + coins_in_hand;	
				self.speed <- base_speed;
			}
		} else {
			do remove_intention(store_coins, true);
		}
		
	}
	
	plan share_information_to_friends intention: share_coinbox_information instantaneous: true{
		list<Worker> my_friends <- list<Worker>((social_link_base where (each.trust > worker_trust_treshold and max(each.trust))) collect each.agent);
		if(not empty(my_friends)){
			Worker my_best_friend <- my_friends[0];
			loop known_coinbox over: get_beliefs_with_name(coinbox_at_location){
				ask my_best_friend{
					do add_directly_belief(known_coinbox);
					do remove_intention(find_coins, false);
				}
			}
			loop known_empty_coinbox over: get_beliefs_with_name(empty_coinbox_location){
				ask my_best_friend {
					do add_belief(known_empty_coinbox);
				}
			}
		}
		do remove_intention(share_coinbox_information, true);
	}
	
	aspect proximity_radius {
		draw circle(worker_proximity_radius) color:#gray empty: true;
	}
}

species socialLinkRepresentation{
    Worker origin;
    agent destination;
    rgb my_color;
    
    reflex update when: every(10#cycle){
    	loop tempWorker over: Worker{
        	loop tempDestination over: tempWorker.social_link_base{
            	if (tempDestination !=nil){
                	loop tempLink over: socialLinkRepresentation{
                    	if((tempLink.origin=tempWorker) and (tempLink.destination=tempDestination.agent)){
                        	if(get_trust(tempDestination)> worker_trust_treshold){
                            	tempLink.my_color <- #green;
                            } else {
                                tempLink.my_color <- #red;
                            }
                        }
                    }           
            	}
        	}
		}
    }
    
    aspect base{
        draw line([origin,destination],1) color: my_color;
    }
}

species CoinBox  {
//	int coins <- rnd(1,max_coins_in_coinbox);
	int coins <- 1;
	
	reflex update when: every(1#cycle){
		if(coins = 0){
			do spawn_new_coinbox;
			do die;
		}
	} 
	
	action spawn_new_coinbox {
		create species(self){
			location <- any_location_in(free_space_without_safezones);
		}
	}
	
	aspect default{
		draw square(5) color: #green; 
	}
}


species Safezone {
	geometry shape <- square(30);
	
	aspect default{
		draw shape color: #green; 
	}
}

experiment PrisonPatrollingGame type: gui {
	parameter "Initial number of guardians: " var: nb_guardians min: 0 max: 50 category: "Base Guardian";
	parameter "Base Perceived Distance: " var: guardian_perception_distance min: 10.0 max: 70.0 category: "Base Guardian";
	parameter "Base Speed: " var: guardian_speed min: 0.7 max: 1.5 category: "Base Guardian";
	parameter "Field of View: " var: guardian_fov min: 30.0 max: 150.0 category: "Base Guardian";
	
	parameter "(Lazy) Initial number of guardians: " var: nb_lazy_guardians min: 0 max: 50 category: "Lazy Guardian";
	parameter "(Lazy) Perceived Distance Bonus %: " var: lazy_guardian_perception_distance_percent_bonus min: -90.0 max: 200.0 category: "Lazy Guardian";
	parameter "(Lazy) Speed Bonus %: " var: lazy_guardian_speed_percent_bonus min: -90.0 max: 200.0 category: "Lazy Guardian";
	parameter "(Lazy) Field of View: " var: lazy_guardian_fov min: 30.0 max: 150.0 category: "Lazy Guardian";
	
	parameter "(Fast) Initial number of guardians: " var:nb_fast_guardians min: 0 max: 50 category: "Fast Guardian";
	parameter "(Fast) Perceived Distance Bonus %: " var: fast_guardian_perception_distance_percent_bonus min: -90.0 max: 200.0 category: "Fast Guardian";
	parameter "(Fast) Speed Bonus %: " var: fast_guardian_speed_percent_bonus min: -90.0 max: 200.0 category: "Fast Guardian";
	parameter "(Fast) Field of View: " var: fast_guardian_fov min: 30.0 max: 150.0 category: "Fast Guardian";
	
	float minimum_cycle_duration <- 0.05;
	output {
		display info {
			chart "Safe coins" type: series {
				datalist legend: Worker accumulate each.name value: Worker accumulate each.coins_safe color:Worker accumulate each.chart_color;
			}
		}
		
		display socialLinks {
        	species socialLinkRepresentation aspect: base;
    	}
		
		display view synchronized: true {
			species obstacle;
			species BaseGuardian aspect: perception transparency: 0.6;
			species BaseGuardian aspect: body;
			species BaseGuardian aspect: proximity_radius;
			
			species LazyGuardian aspect: perception transparency: 0.6;
			species LazyGuardian aspect: body;
			species LazyGuardian aspect: proximity_radius;
			
			species FastGuardian aspect: perception transparency: 0.6;
			species FastGuardian aspect: body;
			species FastGuardian aspect: proximity_radius;
			
			species Worker aspect: perception transparency: 0.6;
			species Worker aspect: body;
			species Worker aspect: proximity_radius;
			
			species Safezone transparency: 0.8;
			species CoinBox;	
		}
		
	}
}