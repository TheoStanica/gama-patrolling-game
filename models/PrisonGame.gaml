/**
* Name: PrisonPatrollingGame
* Based on the internal empty template. 
* Author: teo_t
* Tags: 
*/


model PrisonPatrollingGame

global {
	int env_length <- 200;
	int current_cycle <- 0;
	
	int nb_obstacles <- 15;
	int nb_coinboxes <- 20;
	int max_coins_in_coinbox <- 3;
	int total_guardians_stunned <- 0;
	int total_workers_stunned <- 0;
	int stunned_w01 <- 0;
	int stunned_w02 <- 0;
	int stunned_w03 <- 0;
	int stunned_w04 <- 0;
	int stunned_g01 <- 0;
	int stunned_g02 <- 0;
	int stunned_g03 <- 0;
	int stunned_g04 <- 0;
	 
	
	int nb_workers <- 3;
	float worker_trust_treshold <- 0.4;
	float worker_proximity_radius <- 10.0;
	float worker_socializing_radius <- 15.0;
	float worker_max_energy <- 5.0;
	float worker_strength <- 3.3;
	int  worker_reward_behavior_interval <- 500;
	int coins_required_to_escape <- 20;
	
	int nb_behaving_workers <- 1;
	
	int nb_lying_workers <- 1;
	
	
	int nb_guardians <- 2;
	float guardian_perception_distance <- 30.0;
	float guardian_speed <- 1.0;
	float guardian_fov <- 60.0;
	float maximum_distance_between_self_and_target_to_chase <- 75.0;
	float guard_proximity_radius <- 10.0;
	float guardian_max_energy <- 7.0;
	float guardian_strength <- 3.0;
	int fine_amount <- 2;
	
	int nb_lazy_guardians <- 2;
	float lazy_guardian_speed_percent_bonus <- -50.0;
	float lazy_guardian_perception_distance_percent_bonus <- 45.0;
	float lazy_guardian_fov <- 110.0;
	float lazy_guardian_strength <- 1.0;
	
	int nb_fast_guardians <- 6;
	float fast_guardian_speed_percent_bonus <- 40.0;
	float fast_guardian_perception_distance_percent_bonus <- 20.0;
	float fast_guardian_fov <- 30.0;
	float fast_guardian_strength <- 2.0;
	
	Safezone the_safezone;
	
	
	string coinbox_at_location <- "coinbox_at_location";
	string empty_coinbox_location <- "empty_coinbox_location";
	string misbehaving_worker_location <- "misbehaving_worker_location";
	
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

	
	
	geometry shape <- square(env_length);
	geometry free_space <- copy(shape);
	geometry free_space_without_safezones <- copy(free_space);
	init {		
		loop times: nb_obstacles {
			create obstacle {
				location <- any_location_in(free_space);
				shape <- circle(2+rnd(15));
				free_space <- free_space - shape;
				free_space_without_safezones <- free_space_without_safezones - shape;
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
		create BehavedWorker number: nb_behaving_workers {
			location <- any_location_in(free_space);
		}
		create LyingWorker number: nb_lying_workers {
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
    
    reflex update_current_cycle when: every(1#cycle){
    	current_cycle <- current_cycle + 1;
    }
    
    list<agent> get_all_instances(species<agent> spec) {
		return spec.population + spec.subspecies accumulate(get_all_instances(each)) ;
	}
	
	float avg_guardians_energy <- 1.0;
	int total_nb_guardians <- nb_guardians + nb_lazy_guardians + nb_fast_guardians;
	reflex update_avg_guardians_energy when: every(1#cycle){
		float added_g_energy <- 0.0;
		list<BaseGuardian> guardians <- get_all_instances(BaseGuardian);
		loop guardian over:guardians{
    		added_g_energy <- added_g_energy + guardian.energy;
    	}
    	avg_guardians_energy <- added_g_energy / total_nb_guardians;
	}
    
    
    reflex stop_simulation{
    	list<Worker> workers <- get_all_instances(Worker);
    	loop worker over:workers{
    		if(worker.coins_safe >= coins_required_to_escape){
    			do pause;
    		}
    	}
    }
}

species BaseAgent skills: [moving] control: simple_bdi{
	float perception_distance <- guardian_perception_distance;
	float fov <- guardian_fov;
	float speed <- guardian_speed;
	bool stunned <- false;
	int stunned_cycles <- 0;
	int to_be_stunned_for <- 0;
	rgb my_color <- rnd_color(255);
	rgb current_color <- my_color;
	rgb chart_color <- rnd_color(255);
	float energy <- 1.0;
	float avg_energy <- 1.0;
	
	
	
	geometry perceived_area;
	point target ;
	
	rule belief:is_stunned new_desire: stay_stunned strength: 100.0;
	
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
	
	action stunned(int cycles) {
		to_be_stunned_for <- cycles;
		stunned <- true;	
		do add_belief(is_stunned);
	}
	
	plan stay intention: stay_stunned  when: every(1#cycle) {
		if(stunned_cycles <= to_be_stunned_for){
			stunned_cycles <- stunned_cycles + 1;
		} else {
			stunned <- false;
			stunned_cycles <- 0;
			to_be_stunned_for <- 0;
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
	
	reflex compute_average_energy when:every(1#cycle){
		avg_energy <- avg_energy + (energy - avg_energy)/current_cycle;
	}
	
	aspect body {
		draw circle(1) color: current_color;
	}
	
	aspect perception {
		if (perceived_area != nil) {
			draw perceived_area color: current_color;
			draw circle(1) at: target color: #pink;
		}
	}
	aspect stunned {
		if(stunned){
			current_color <- #yellow;
		} else {
			current_color <- my_color;
		}
		
	}
}

species BaseGuardian parent:BaseAgent {
	float perception_distance <- guardian_perception_distance;
	float guard_proximity_rad <- guard_proximity_radius;
	float fov <- guardian_fov;
	float base_speed <- guardian_speed;
	float speed <- base_speed;
	float max_energy <- guardian_max_energy;
	float energy <- 1.0;
	float strength <- guardian_strength;
	int fine <- fine_amount;
	rgb my_color <- #blue;
	int nb_won_fights <- 0;
	int nb_lost_fights <- 0;
	
	rule belief:misbehaving_worker new_desire:chase_worker strength: 2.0;
	
	init {
		do add_desire(patrol, 1.0);
	}
	
	reflex update when: energy < max_energy {
		energy <- energy + 0.015;  // +1 energy every 67 steps 			
	}
	
	perceive target: agents of_generic_species BaseGuardian  in: free_space{
		socialize;
	}
	
	perceive target:agents of_generic_species Worker in: union([perceived_area,circle(guard_proximity_rad)]) when: every(1#cycle) {
		if(myself.perceived_area != nil){
			if( self.has_belief(has_coin_in_hand)){
				Worker msb_w <- self;
				ask myself{
					do add_belief(new_predicate(misbehaving_worker_location, ['misbehaving_worker'::msb_w]));
					do decideToChase;
				}
			} 
		}
	}
	
	action decideToChase{
		do remove_intention(patrol, false);
		do add_belief(misbehaving_worker);
		do add_desire(predicate: share_info_about_misbehaving_worker, strength: 15.0);
		do add_desire(predicate: chase_worker, strength: 10.0, todo: chase_worker);
	}
	
	plan patrolling intention: patrol{
		do moving_around;
	}
	
	plan tell_guardians_about_misbehaving_worker intention: share_info_about_misbehaving_worker instantaneous: true{
		list<Worker> misbehaving_workers <- get_beliefs_with_name(misbehaving_worker_location) collect (get_predicate(mental_state (each)).values["misbehaving_worker"]);
		if(empty(misbehaving_workers) = false){
			list<BaseGuardian> all_guardians <- list<BaseGuardian>(social_link_base  collect each.agent);
			loop worker over:misbehaving_workers {
				list<BaseGuardian> close_enough_guardians <- list<BaseGuardian>( all_guardians where (each distance_to worker < maximum_distance_between_self_and_target_to_chase));
				ask close_enough_guardians {
					do remove_intention(patrol, false);
					do add_belief(new_predicate(misbehaving_worker_location, ['misbehaving_worker'::worker]));
					do add_belief(misbehaving_worker);
				}
			}
		}
		do remove_intention(share_info_about_misbehaving_worker, true);
	}
	
	plan chaseWorker intention: chase_worker {
		list<Worker> misbehaving_workers <- get_beliefs_with_name(misbehaving_worker_location) collect (get_predicate(mental_state (each)).values["misbehaving_worker"]);	
		if(empty(misbehaving_workers)){
			do remove_intention(chase_worker, true);
			do add_intention(patrol);
		} else {
			Worker target_worker <- (misbehaving_workers with_min_of(each distance_to self));
			if(target_worker.has_belief(has_coin_in_hand)){
				do goToPlace goTo: target_worker.location;
				if(energy > 0.0){
					speed <- base_speed + base_speed * (energy * 0.07);    //  49.5% max bonus speed
					energy <- energy - 0.07;			
				}
				if(distance_to(self.location, target_worker.location) < 0.5 ){	
					do attack_worker(target_worker);
					do remove_intention(chase_worker, true);
					do remove_belief(new_predicate(misbehaving_worker_location, ["misbehaving_worker"::target_worker]));	
				}
			} else {
				speed <- base_speed;
				do remove_belief(new_predicate(misbehaving_worker_location, ["misbehaving_worker"::target_worker]));
			}	
		}
	}

	action attack_worker(Worker worker_target) {
		Worker worker <- worker_target;
		int my_RNG <- rnd(-15,15);
		int worker_RNG <- rnd(-15,15);
		
		float my_attack_score <- energy + strength + base_speed;
		my_attack_score <- my_attack_score + (abs(my_attack_score ) * my_RNG)/100.0;

		float worker_attack_score <- worker.energy + worker.strength + worker.base_speed;
		worker_attack_score <- worker_attack_score + (abs(worker_attack_score ) * worker_RNG)/100.0;
		
		float difference <- my_attack_score - worker_attack_score;
		
		if(difference >= 0){
			ask worker{
				coins_in_hand <- 0;
				do remove_belief(has_coin_in_hand);
				coins_safe <- coins_safe - myself.fine;		
				cycles_left_for_reward <- worker_reward_behavior_interval;
				do stunned(25 * int(abs(difference) + 1));		
			}
			nb_won_fights <- nb_won_fights + 1;
			total_workers_stunned <- total_workers_stunned + 1;
			
			
			if(avg_guardians_energy <= 1.75){
				stunned_w01 <- stunned_w01 + 1;
			} else if(avg_guardians_energy <= 3.5){
				stunned_w02 <- stunned_w02 + 1;
			} else if(avg_guardians_energy <= 5.25) {
				stunned_w03 <- stunned_w03 + 1;
			} else {
				stunned_w04 <- stunned_w04 + 1;
			}
		
		} else {
			ask self {
				do stunned(25 * int(abs(difference) + 1));
			}
			total_guardians_stunned <- total_guardians_stunned + 1;
			nb_lost_fights <- nb_lost_fights + 1;
			if(avg_guardians_energy <= 1.75){
				stunned_g01 <- stunned_g01 + 1;
			} else if(avg_guardians_energy <= 3.5){
				stunned_g02 <- stunned_g02 + 1;
			} else if(avg_guardians_energy <= 5.25) {
				stunned_g03 <- stunned_g03 + 1;
			} else {
				stunned_g04 <- stunned_g04 + 1;
			}
		}
		self.speed <- base_speed;	
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
	int cycles_left_for_reward <- worker_reward_behavior_interval;
	int coins_needed_to_escape <- coins_required_to_escape;
	float worker_socializing_rad <- worker_socializing_radius;
	float worker_proximity_rad <- worker_proximity_radius;
	int coins_in_hand <- 0;
	int coins_safe <- 0;
	float max_energy <- worker_max_energy;
	float energy <- 1.0;
	float base_speed <- 1.0;
	float strength <- worker_strength;
	rgb my_color <- #red;
	int nb_just_escaped <- 0;
	bool is_being_chased <- false;
	
	bool use_social_architecture <- true;

	rule belief: coinbox_location new_desire: get_coins strength: 2.0;
	rule belief: has_coin_in_hand new_desire: store_coins strength: 3.0;	
	
	init{
		do add_desire(find_coins, 1.0);
	}
	
	reflex update when: energy < max_energy {
		energy <- energy + 0.015;  // +1 energy every 67 steps 			
	}
	
	reflex reward_behavior when: cycles_left_for_reward = 0{
		coins_safe <- coins_safe + 1;
		cycles_left_for_reward <- worker_reward_behavior_interval;
	}
	
	reflex update_reward_cycles_left when:every(1#cycle) {
		cycles_left_for_reward <- cycles_left_for_reward - 1;
	}
	
	perceive target: agents of_generic_species BaseGuardian in:worker_proximity_rad  when: has_belief(has_coin_in_hand) {
		if(myself.energy > 0.0){
			myself.speed <- myself.base_speed + myself.base_speed*(myself.energy * 0.07);    //  35% max bonus speed
			myself.energy <- myself.energy - 0.07;
			myself.is_being_chased <- true;
		} 
	}	
	
	perceive target: CoinBox in:union([perceived_area,circle(worker_proximity_rad)]) when: every(1#cycle){
		if(myself.perceived_area != nil){
			focus id: coinbox_at_location var: location;
			ask myself{
				do add_desire(predicate: share_coinbox_information, strength: 5.0);
				do remove_intention(find_coins, false);
			}
		}
	}
	
	perceive target: agents of_generic_species Worker in: worker_socializing_rad {
		if(self != myself){
			socialize liking:0.1;
			do change_trust(self, 0.009);	
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
				coins_in_hand <- 0;
				self.speed <- base_speed;
				if(is_being_chased){
					nb_just_escaped <- nb_just_escaped + 1;
					is_being_chased <- false;
				}
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

species BehavedWorker parent: Worker {
	rgb my_color <- #green;
	plan getting_coins intention: get_coins{
		do moving_around;
	}
}

species LyingWorker parent: Worker {
	rgb my_color <- #purple;
	
	plan share_information_to_friends intention: share_coinbox_information instantaneous: true{
		do remove_intention(share_coinbox_information, true);
	}
	
	reflex tell_lies when: every(100#cycles){
		float chance <- rnd(0.0, 1.0);
		if(chance <= 0.30){
			list<Worker> workers_i_know <- list<Worker>(social_link_base collect each.agent);
			ask workers_i_know{
				do add_belief(new_predicate(coinbox_at_location, ["location_value"::myself.location]));
				do remove_intention(find_coins, false);
			}
		}
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

species obstacle {
	aspect default {
		draw shape color: #gray ;
	}
}

species CoinBox  {
	int coins <- rnd(1,max_coins_in_coinbox);
	image_file my_icon <- image_file('../includes/box-full.png'); 
	
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
		draw my_icon size: 5 color: #green; 
	}
}


species Safezone {
	geometry shape <- square(30);
	image_file my_icon <- image_file('../includes/safe-zone.png'); 
	
	aspect default{
		draw my_icon size: 30 color: #green; 
	}
}

experiment PrisonPatrollingGame type: gui {
	parameter "Number of obstacles" var: nb_obstacles min: 0 max: 50;
	parameter "Number of coinboxes" var: nb_coinboxes min: 0 max: 10;
	parameter "Maximum number of coins in a coinbox" var: max_coins_in_coinbox min: 1 max: 5;
	
	parameter "Number of Workers" var: nb_workers min: 0 max: 10 category: "Worker";
	parameter "Worker Trust Treshold" var: worker_trust_treshold min: 0.0 max: 1.0 category: "Worker";
	parameter "Worker Proximity Radius" var: worker_proximity_radius min: 1.0 max: 20.0 category: "Worker";
	parameter "Worker Socializing Radius" var: worker_socializing_radius min: 1.0 max: 20.0 category: "Worker";
	parameter "Worker Max Energy" var: worker_max_energy min: 1.0 max: 10.0 category: "Worker";
	parameter "Worker Strength" var: worker_strength min: 1.0 max: 10.0 category: "Worker";
	parameter "Reward After Cycles" var: worker_reward_behavior_interval min: 100 max: 1000 category: "Worker";
	parameter "Coins Required to Escape" var: coins_required_to_escape min: 1 max: 50 category: "Worker";
	
	
	parameter "(Behaving) Number of workers" var: nb_behaving_workers min: 0 max: 10 category: "Behaving Worker";
	
	
	parameter "(Lying) Number of workers" var: nb_lying_workers min: 0 max: 10 category: "Lying Worker";
	
	
	parameter "Number of guardians" var: nb_guardians min: 0 max: 50 category: "Base Guardian";
	parameter "Base Perceived Distance" var: guardian_perception_distance min: 10.0 max: 70.0 category: "Base Guardian";
	parameter "Base Speed" var: guardian_speed min: 0.7 max: 1.5 category: "Base Guardian";
	parameter "Field of View" var: guardian_fov min: 30.0 max: 120.0 category: "Base Guardian";
	parameter "Max Distance to Chase" var: maximum_distance_between_self_and_target_to_chase min: 10.0 max: 100.0 category: "Base Guardian";
	parameter "Proximity Radius" var: guard_proximity_radius min: 1.0 max: 20.0 category: "Base Guardian";
	parameter "Max Energy" var: guardian_max_energy min: 1.0 max: 10.0 category: "Base Guardian";
	parameter "Strength" var: guardian_strength min: 1.0 max: 10.0 category: "Base Guardian";
	parameter "Fine" var: fine_amount min: 1 max: 5 category: "Base Guardian";
 	
	
	parameter "(Lazy) Number of guardians" var: nb_lazy_guardians min: 0 max: 50 category: "Lazy Guardian";
	parameter "(Lazy) Perceived Distance Bonus %" var: lazy_guardian_perception_distance_percent_bonus min: -90.0 max: 200.0 category: "Lazy Guardian";
	parameter "(Lazy) Speed Bonus %" var: lazy_guardian_speed_percent_bonus min: -90.0 max: 200.0 category: "Lazy Guardian";
	parameter "(Lazy) Field of View" var: lazy_guardian_fov min: 30.0 max: 120.0 category: "Lazy Guardian";
	parameter "(Lazy) Strength" var: lazy_guardian_strength min: 1.0 max: 10.0 category: "Lazy Guardian";
	
	
	parameter "(Fast) Number of guardians" var:nb_fast_guardians min: 0 max: 50 category: "Fast Guardian";
	parameter "(Fast) Perceived Distance Bonus %" var: fast_guardian_perception_distance_percent_bonus min: -90.0 max: 200.0 category: "Fast Guardian";
	parameter "(Fast) Speed Bonus %" var: fast_guardian_speed_percent_bonus min: -90.0 max: 200.0 category: "Fast Guardian";
	parameter "(Fast) Field of View" var: fast_guardian_fov min: 30.0 max: 120.0 category: "Fast Guardian";
	parameter "(Fast) Strength" var: fast_guardian_strength min: 1.0 max: 10.0 category: "Fast Guardian";
	
	float minimum_cycle_duration <- 0.05;
	output {		
		display socialLinks {
        	species socialLinkRepresentation aspect: base;
    	}
    	
    	display Guardian_information refresh: every(5#cycles) {
			chart "Energy" type: histogram background: #lightgray size: {0.5,0.5} position: {0, 0.5} {
				loop guardian over:agents of_generic_species BaseGuardian {
					data guardian.name value: guardian.energy color: guardian.chart_color;
				}
			}
			chart "Average Energy" type: histogram background: #lightgray size: {0.5,0.5} position: {0.5, 0.5} {				
				loop guardian over:agents of_generic_species BaseGuardian {
					data guardian.name value: guardian.avg_energy color: guardian.chart_color;
				}
			}
			chart "Fights Won" type: histogram background: #lightgray size: {0.5,0.5} position: {0, 0} {				
				loop guardian over:agents of_generic_species BaseGuardian {
					data guardian.name value: guardian.nb_won_fights color: guardian.chart_color;
				}
			}
			chart "Fights Lost" type: histogram background: #lightgray size: {0.5,0.5} position: {0.5, 0} {				
				loop guardian over:agents of_generic_species BaseGuardian {
					data guardian.name value: guardian.nb_lost_fights color: guardian.chart_color;
				}
			}
		}
		
		display Worker_information refresh: every(5#cycles) { 
			chart "Coins safe" type: histogram background: #lightgray size: {0.5,0.5} position: {0, 0} {
				loop worker over:agents of_generic_species Worker {
					data worker.name value: worker.coins_safe color: worker.chart_color;
				}
			}
			chart "Times just escaped" type: histogram background: #lightgray size: {0.5,0.5} position: {0.5, 0} {
				loop worker over:agents of_generic_species Worker {
					data worker.name value: worker.nb_just_escaped color: worker.chart_color;
				}
			}
			chart "Energy" type: histogram background: #lightgray size: {0.5,0.5} position: {0, 0.5} {
				loop worker over:agents of_generic_species Worker {
					data worker.name value: worker.energy color: worker.chart_color;
				}
			}
			chart "Average Energy" type: histogram background: #lightgray size: {0.5,0.5} position: {0.5, 0.5} {				
				loop worker over:agents of_generic_species Worker {
					data worker.name value: worker.avg_energy color: worker.chart_color;
				}
			}
		}
		
		display General_information refresh: every(5#cycles) { 
			chart "Safe coins" type: series size: {1.0, 0.5} position: {0,0} {
				datalist legend: agents of_generic_species Worker accumulate each.name value: agents of_generic_species Worker accumulate each.coins_safe color:agents of_generic_species Worker accumulate each.chart_color;
			}
			chart "Stunned agents" type: histogram background: #lightgray size: {0.33,0.5} position: {0, 0.5} {
				data "Workers" value: total_workers_stunned use_second_y_axis: true;
				data "Guardians" value: total_guardians_stunned;
			}
			chart "Worker Stunned/Average Guardian Energy Distribution" type: histogram background: #lightgray size: {0.33,0.5} position: {0.33, 0.5} {
				data "[0,1.75)" value: stunned_w01 color: #red;
				data "[1.75,3.5)" value:stunned_w02 color: #red;
				data "[3.5,5.25)" value:stunned_w03 color: #red;
				data "[5.25,7]" value:stunned_w04 color: #red;
			}
			chart "Guardians Stunned/Average Guardian Energy Distribution" type: histogram background: #lightgray size: {0.33,0.5} position: {0.66, 0.5}  {
				data "[0,1.75)" value: stunned_g01 color: #blue;
				data "[1.75,3.5)" value:stunned_g02 color: #blue;
				data "[3.5,5.25)" value:stunned_g03 color: #blue;
				data "[5.25,7]" value:stunned_g04 color: #blue;
			}
			
		}
		
		display Energy_Fights_Evolution refresh: every(5#cycle){
			chart "Average Energy" type: series  size: {1.0,0.5} position: {0,0}{				
				data legend: "Guardians average energy" value: avg_guardians_energy color: #green;
			}
			chart "Stunned Agents " type: series  size: {1.0,0.5} position: {0,0.5}{				
				data legend: "Number of stunned Guardians" value: total_guardians_stunned color: #blue;
				data legend: "Number of sutnned Workers" value: total_workers_stunned color: #red;
			}
			
		}
		
		display view synchronized: true {
			species obstacle;
			species BaseGuardian aspect: perception transparency: 0.6;
			species BaseGuardian aspect: body;
			species BaseGuardian aspect: proximity_radius;
			species BaseGuardian aspect: stunned;
			
			
			species LazyGuardian aspect: perception transparency: 0.6;
			species LazyGuardian aspect: body;
			species LazyGuardian aspect: proximity_radius;
			species LazyGuardian aspect: stunned;
			
			species FastGuardian aspect: perception transparency: 0.6;
			species FastGuardian aspect: body;
			species FastGuardian aspect: proximity_radius;
			species FastGuardian aspect: stunned;
			
			species Worker aspect: perception transparency: 0.6;
			species Worker aspect: body;
			species Worker aspect: proximity_radius;
			species Worker aspect: stunned;
			
			species BehavedWorker aspect: perception transparency: 0.6;
			species BehavedWorker aspect: body;
			species BehavedWorker aspect: proximity_radius;
			species BehavedWorker aspect: stunned;
			
			species LyingWorker aspect: perception transparency: 0.6;
			species LyingWorker aspect: body;
			species LyingWorker aspect: proximity_radius;
			species LyingWorker aspect: stunned;
			
			species Safezone transparency: 0.5;
			species CoinBox;	
		}
	}
}