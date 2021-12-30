# Gama Patrolling Game
BDI model simulating a patrolling game using [GAMA-Platform](https://gama-platform.org/).

# Game Rules and Features
## Features
To create this simulation I have decided I want to add the following features:
- Obstacles that are added dynamically every simulation
- Random coin boxes are added dynamically in the environment every simulation
- Once a coin box reaches 0 coins, it gets destroyed and a new coin box appears in a random location in the environment
- All human agents must have a perceived area where they can locate other agents. This area is determined by a series of factors including perception distance and field of view
- All agents must have other characteristics such as speed, energy and strength
- Workers are the agents that want to escape the environment. They must reach a given amount of collected coins to escape and "win" the simulation
- Workers move around the environment trying to find coin boxes. Once they reach a coin box they steal a coin from it and hold it in their hands
- Holding a coin in hand is considered a misbehavior in this simulation. Once a worker knows they have a coin in hand, they want to store them in the Safe zone
- Once the worker stored the coin in the Safe zone, they no longer are holding a coin in hand and therefore are following the game rules
- Workers socialize with each other. The longer they stay around each other, the more they trust the other worker
- Once a worker found a coin box, they want to share that information to other workers they know and trust enough
- Workers are rewarded 1 coin after some time without doing anything
- Create a worker that follows the game rule to not hold coins in hand. This worker will only get coins from rewards
- Create a worker that sends wrong locations of coin boxes to all workers they have interacted with and try to slow them down
- Guardians are the agents that try to make sure that rules are followed by workers
- When guardians detect a worker that holds a coin in hand they try to reach and sanction them
- When guardians detect a worker misbehaving they will tell other guardians about that worker. Other agents will determine if the worker is close enough and start chasing
- When guardians decide to chase a worker, they start running. Their speed is influenced by their current energy level and normal speed
- When worker agents detect a guardian chasing them in their proximity range they start running too. Their speed is influenced by their current energy level and normal speed
- when guardians reach the misbehaving worker they will attack them. Both agents have a current energy level, normal speed and strength. This determines their "attack power". This way when workers are attacked they can win the fight
- When guardians win the fight, they will get back the coin that the worker agent is holding and will fine them
- When workers win the fight, they will run away unharmed
- After an agent lost a fight, they will be stunned for an amount of time. This time is different based on the difference of the two agents' attack power. A higher difference of power will resutl in a longer stun period

## Game Rules
There are two rules for this game:
- Worker agents are not expected to steal coins
- When worker agents reach some amount of coins they will escape

# Agent Types
- Obstacle - Basic obstacle on map
- Coinbox - Coin box that holds a random amount of coins. Despawns and creates a new Coinbox agent when the number of coins inside of it reaches 0
- Safezone - Location where worker agents store stolen coins
- BaseAgent - Parent agent that handles basic skills such as moving on the map, updating perceived area and being stunned action
- Worker - Holds all the skills required for worker agent species including finding coin boxes, picking up coins, storing them at the safe zone, sharing information about coin boxes locations and running away from guardians chasing them,
- BehavedWorker - Worker that does not pick up any coins and follows the rules
- LyingWorker - Worker that shares misinformation about coin box location at random intervals
- socialLinkRepresentation - Handles displaying workers social link representation
- BaseGuardian - Holds all skills required for guardian agent species including patrolling, detecting misbehaving workers, sharing information to other buardians about misbehaving workers, chasing, attacking and sanctioning workers.
- LazyGuardian - Has the same skills as BaseGuardian but lower speed, bigger perception distance, increased field of view and very low strength. This agent has the role of being a "spotter" and has very low chances of catching workers
- FastGuardian - Has the same skills as BaseGuardian but increased speed, highest perception distance, lowest field of view and low strength. This agent has the role of catching workers

# Parameters
The simulation has multiple parameters that can be easily changed. These are split in different categories:
- General
  - Number of obstacles - Represents the number of dynamically generated obstacles during the simulation
  - Number of coinboxes - Represents the initial number of coin boxes that will be generated during the simulation
  - Maximum number of coins in a coinbox - Represents the maximum amount of coins that a coin box can hold during the simulation
- Worker
  - Number of Workers - Represents the number of normal workers that will be created for the simulation
  - Worker Trust Treshold - Represents the minimum trust treshold required to trust a worker and share coin box locations with them
  - Woker Proximity Radius - Worker's proximity radius
  - Worker Socializing Radius - Similar with Proximity Radius but for socializing
  - Worker Max Energy - Worker's maximum energy
  - Worker Strength - Worker's strength
  - Reward After Cycles - The number of cycles after witch a worker agent will get 1 coin as reward
  - Coins Required to Escape - The amount of coins a worker needs to escape and win the game
- Behaving Worker
  - (Behaving) Number of workers - Represents the number of behaving workers that will be created for the simulation
- Lying Worker
  - (Lying) Number of workers - Represents the number of lying workers that will be created for the simulation
- Base Guardian
  - Number of guardians - Represents the number of normal guardians that will be created for the simulation
  - Base Perceived Distance - How far can the guardian see
  - Base Speed - Guardian's normal speed
  - Field of View - Guardian's field of view
  - Max Distance to Chase - The maximum distance between the guardian and a misbehaving worker for the guardian to start chasing
  - Proximity Radius - Guardian's proximity radius
  - Max Energy - Guardian's maximum energy
  - Strength - Guardian's strength
  - Fine - The amount of coins that will be given as a fine to workers caught misbehaving
- Lazy Guardian
  - (Lazy) Number of guardians - Represents the number of lazy guardians that will be created for the simulation
  - (Lazy) Perceive distance bonus % - Bonus perceived distance in %. Uses base guardian perceived distance
  - (Lazy) Speed Bonus %% - Bonus speed in %. Uses base guardian base speed
  - (Lazy) Field of View - Guardian's field of view
  - (Lazy) Strength - Guardian's strength
- Fast Guardian
  - (Fast) Number of guardians - Represents the number of fast guardians that will be created for the simulation
  - (Fast) Perceive distance bonus % - Bonus perceived distance in %. Uses base guardian perceived distance
  - (Fast) Speed Bonus %% - Bonus speed in %. Uses base guardian base speed
  - (Fast) Field of View - Guardian's field of view
  - (Fast) Strength - Guardian's strength


