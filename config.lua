Config = {}

Config.Debug = true --false on live server

Config.UseTax = false --if true taxes will be collected from players
Config.TaxDay = 23 --This is the number day of each month that taxes will be collected on
Config.TaxResetDay = 24 --This MUST be the day after TaxDay set above!!! (do not change either of these dates if the current date is one of the 2 for ex if its the 22 or 23rd day do not change these dates it will break the code)

Config.useCharacterJob = true --if true players are employeed at a ranch via a characters.job if false players are employeed at a ranch via a character variable
-- Set Language (Current Languages: "en_lang" English, "fr_lang" French, "de_lang" German, "pt_lang" Portuguese-Brazilian)
Config.defaultlang = "de_lang"

--Webhok Setup
Config.Webhooks = {
    RanchCreation = { --ranch creation webhook
        WebhookLink = '', --insert your webhook link here(leave blank for no webhooks)
        --- Dont Change Just Translate ----
        TitleText = 'Admin Character Static id ',
        Text = 'Has Created A Ranch and given it too Character Static ID '
    },
    AnimalBought = {
        WebhookLink = '', --insert your webhook link here(leave blank for no webhooks)
        ----- Dont Change just translate ----
        TitleText = 'Ranch Id ',
        DescText = 'Bought ',
        Cows = 'Cows',
        Pigs = 'Pigs',
        Goats = 'Goats',
        Chickens = 'Chickens',
    },
    AnimalSold = {
        WebhookLink = '', --insert your webhook link (leave blank for no webhook)
        ----- Dont Change Just Translate -----
        TitleText = 'Ranch ID ',
        Sold = 'Sold ',
        Cows = 'Cows for: ',
        Pigs = 'Pigs for: ',
        Goats = 'Goats for: ',
        Chickens = 'Chickens for: ',
    },
    Taxes = { --ranch creation webhook
    WebhookLink = '', --insert your webhook link here(leave blank for no webhooks)
    --- Dont Change Just Translate ----
    TitleText = 'Admin Character Static id ',
    Text = 'Has Created A Ranch and given it too Character Static ID '
    },
}

---- Thise is the chore config
Config.ChoreMinigames = true --if true a minigame will have to be completed to finish the chore!
--Minigame setup ONLY CHANGE DO NOT REMOVE ANYTHING!
Config.ChoreMinigameConfig = {
    focus = true, -- Should minigame take nui focus (required)
    cursor = false, -- Should minigame have cursor
    maxattempts = 2, -- How many fail attempts are allowed before game over
    type = 'bar', -- What should the bar look like. (bar, trailing)
    userandomkey = false, -- Should the minigame generate a random key to press?
    keytopress = 'E', -- userandomkey must be false for this to work. Static key to press
    keycode = 69, -- The JS keycode for the keytopress
    speed = 25, -- How fast the orbiter grows
    strict = true -- if true, letting the timer run out counts as a failed attempt
}

Config.MilkingMinigameConfig = {
    focus = true, -- Should minigame take nui focus (required)
    cursor = true, -- Should minigame have cursor  (required)
    timer = 30, -- The amount of seconds the game will run for
    minMilkPerSqueez = 100.0,
    maxMilkPerSqueez = 200.0
}

--Main Chore Setup
Config.ChoreConfig = {
    HayChore = {
        AnimTime = 15000, --time the animation will play for
        ConditionIncrease = 5, --amount the condition will increase by
    },
    WaterAnimals = {
        AnimTime = 10000,
        ConditionIncrease = 5,
    },
    RepairFeedTrough = {
        AnimTime = 20000,
        ConditionIncrease = 5,
    },
    ShovelPoop = {
        RecievedItem = 'poop', --You will recieve this item upon completion of this chore(database name of the item)
        RecievedAmount = 1, --this is the amount of the item you will recieve (set 0 if you do not want this feature)
        AnimTime = 15000,
        ConditionIncrease = 5,
    },
}

--Main Ranch Setup
Config.RanchSetup = {
    manageRanchCommand = {
        enabled = true, --if enabled players will be able to use command
        commandName = 'manageMyRanch', --name of the command (this command will allow players to open thier ranch menu using the command aslong as they are within thier ranch's set radius)
    },
    animalFollowSettings = { --set the offset that the ranch animals will follow the player around while herding or selling test around to find whatt you like
        offsetX = 5,
        offsetY = 5,
        offsetZ = 0 --Recommended to leave at 0 this is the height variable
    },
    AnimalGrownAge = 100, -- the age the animals will have to be reach before they are grown(animals below this age will be considered babies, and you can not sell or butcher them the age increase while the player is online)
    AnimalsRoamRanch = true, --if you want your animals to roam your ranch set this true
    WolfAttacks = false, --if true there is a chance 2 wolves will spawn while herding or selling animals and attack you!(50 50 chance)
    AnimalsWalkOnly = false, --If true animals that you herd or sell will only be able to walk, if false they can run. (Cows will not run no matter what)
    RanchCondDecrease = 1800000, --This is how often the ranches condition will decrease over time
    UseInventory = false, --if true players will be able to store items in thier ranch inventory
    InvLimit = 200, --Maximum inventory space the ranch will have
    InvName = 'Ranch Inventory', --Name of the inventory
    RanchCondDecreaseAmount = 2, --how much it will decrease
    MaxRanchCondition = 100, --This is the maximum ranch condition possible. This can only be set upto 999
    BlipHash = 'blip_mp_roundup', --ranch blip hash
    HerdingMinDistance = 150, --this is the minimum distance a player will have to be from there ranch to set thier herd location
    ChoreCooldown = 1800, -- seconds in between being able to do chores (30min)
    FeedCooldown = 10800, -- wert: 60*60*2.5 seconds in between being able to feed animals
    RanchAnimalSetup = { --ranch animal setup
        Cows = {
            Health = 200, --How much health the cows will have while being herded or sold 
            AgeIncreaseTime = 3600000, --The time that has to pass before the animals age increases
            AgeIncreaseAmount = 1, --the amount the age will increase
            MilkingCooldown = 7200, --time in seconds you have to  wait before being able to milk them again
            MilkingItem = 'milk', --item recieved after milking
            MilkingItemAmount = 2, --the amount of the item you get
            AmountToCollect = 0.70, --The minimum amount of milk you need to collect from the minigame to successfully milk the cow!
            RoamingRadius = 4.0, --this is the radius the cows will be able to roam around the ranch in(Make sure this is a decimal number ie 0.2, 5.0, 3.9 not a whole number ie 1, 2, 3 will break them wandering if its a whole number)
            MaxCondition = 200, --the maximum condition the animal can reach
            --
            Cost = 200, --cost to buy animal
            LowPay = 200, --This is the amount that will be payed if any animals die along the way
            BasePay = 200, --This is the base pay(what will be paid when selling the animal if animal condition is not max)
            MaxConditionPay = 250, --amount to pay when selling the animal if the animals condition is maxed
            --
            AmountSpawned = 4, --Amount of animals that will spawn when herding or selling them
            FeedCooldown = 10800, -- (3h) time in seconds you have to wait before being able to feed them again
            FeedAnimalCondIncrease = 15, --how much the animal condition will go up after feeding them!
            FoodAmount = 8, --amount of food the animals will eat per feeding
            FoodItem = 'animalfood_cow', --item the animals will eat
            ChoreCooldown = 10800,  -- (3h) seconds in between being able to do chores
            CondIncreasePerHerd = 6, --this is the amount the animals condition will increase when successfully herded!
            CondIncreasePerHerdNotMaxRanchCond = 3, --this is the amount the animals condition will go up per herd if the ranchs condition is not max
            ButcherItems = { --items you will get when you butcher this animal
                {
                    name = 'meat_red', --item db name
                    count = 164, --amount you will get
                }, --you can add more by copy pasting this table
            },
        },
        Pigs = {
            Health = 200, --How much health the pigs will have while being herded or sold
            AgeIncreaseTime = 3600000, --The time that has to pass before the animals age increases
            AgeIncreaseAmount = 2, --the amount the age will increase
            RoamingRadius = 4.0,
            MaxCondition = 200,
            --
            Cost = 150,
            LowPay = 150, --This is the amount that will be payed if any animals die along the way
            BasePay = 150,
            MaxConditionPay = 175,
            --
            AmountSpawned = 4, --Amount of animals that will spawn when herding or selling them
            FeedCooldown = 3600, -- (1h) time in seconds you have to wait before being able to feed them again
            FeedAnimalCondIncrease = 15, --how much the animal condition will go up after feeding them!
            FoodAmount = 2, --amount of food the animals will eat per feeding
            FoodItem = 'animalfood_pig', --item the animals will eat
            CondIncreasePerHerd = 6, --this is the amount the animals condition will increase when successfully herded!
            CondIncreasePerHerdNotMaxRanchCond = 3, --this is the amount the animals condition will go up per herd if the ranchs condition is not max
            ButcherItems = { --items you will get when you butcher this animal
                {
                    name = 'meat_red', --item db name
                    count = 20, --amount you will get
                }, --you can add more by copy pasting this table
                {
                    name = 'fat', --item db name
                    count = 20, --amount you will get
                }, --you can add more by copy pasting this table
            },
        },
        Goats = {
            Health = 200, --How much health the goats will have while being herded or sold
            AgeIncreaseTime = 3600000, --The time that has to pass before the animals age increases
            AgeIncreaseAmount = 2, --the amount the age will increase
            RoamingRadius = 4.0,
            MaxCondition = 200,
            --
            Cost = 150,
            LowPay = 150, --This is the amount that will be payed if any animals die along the way
            BasePay = 150,--This is the base pay(what will be paid when selling the animal if animal condition is not max)
            MaxConditionPay = 175,
            --
            AmountSpawned = 4, --Amount of animals that will spawn when herding or selling them
            FeedCooldown = 10800, -- (1h) time in seconds you have to wait before being able to feed them again
            FeedAnimalCondIncrease = 15, --how much the animal condition will go up after feeding them!
            FoodAmount = 2, --amount of food the animals will eat per feeding
            FoodItem = 'animalfood_goat', --item the animals will eat
            ChoreCooldown = 3600,  -- (1h) seconds in between being able to do chores
            CondIncreasePerHerd = 15, --this is the amount the animals condition will increase when successfully herded!
            CondIncreasePerHerdNotMaxRanchCond = 6, --this is the amount the animals condition will go up per herd if the ranchs condition is not max
            ButcherItems = { --items you will get when you butcher this animal
                {
                    name = 'meat_red', --item db name
                    count = 20, --amount you will get
                }, --you can add more by copy pasting this table
                {
                    name = 'wool', --item db name
                    count = 25, --amount you will get
                }, --you can add more by copy pasting this table
            },
        },
        Chickens = {
            Health = 200, --How much health the chickens will have while being herded or sold
            AgeIncreaseTime = 3600000, --The time that has to pass before the animals age increases
            AgeIncreaseAmount = 25, --the amount the age will increase
            CoopCost = 200, --cost to buy a chicken coop
            CoopCollectionCooldownTime = 1000*60*60*2, --Time in ms that must pass before you can harvest eggs from the coop again
            EggItem = 'egg', --The item you will get from harvesting eggs from the coop
            EggItem_Amount = 6, --the amount of the item you will get
            --
            Cost = 50,
            LowPay = 50, --This is the amount that will be payed if any animals die along the way
            BasePay = 50,--This is the base pay(what will be paid when selling the animal if animal condition is not max)
            MaxConditionPay = 75,
            --
            RoamingRadius = 4.0,
            MaxCondition = 200,
            AmountSpawned = 4, --Amount of animals that will spawn when herding or selling them
            FeedCooldown = 1800, -- (30min) time in seconds you have to wait before being able to feed them again
            FeedAnimalCondIncrease = 25, --how much the animal condition will go up after feeding them!
            FoodAmount = 8, --amount of food the animals will eat per feeding
            FoodItem = 'animalfood_chicken', --item the animals will eat
            ChoreCooldown = 3600,  -- (1h) seconds in between being able to do chores
            CondIncreasePerHerd = 15, --this is the amount the animals condition will increase when successfully herded!
            CondIncreasePerHerdNotMaxRanchCond = 6, --this is the amount the animals condition will go up per herd if the ranchs condition is not max
            ButcherItems = { --items you will get when you butcher this animal
                {
                    name = 'meat_poultry', --item db name
                    count = 50, --amount you will get
                }, --you can add more by copy pasting this table
                {
                    name = 'feather', --item db name
                    count = 20, --amount you will get
                }, --you can add more by copy pasting this table
            },
        },
    }
}

Config.SaleLocationBlipHash = 'blip_ambient_herd' --hash of the blip to show
Config.SaleLocations = {
    --These are the locations players will be able to sell thier cattle/animals at
    {
        LocationName = 'Valentine Cattle Auction', --this will be the name of the blip
        Coords = {x=-217.18, y=634.94, z=113.20}, --the coords the player will have to go to
    }, --to add more just copy this table paste and change what you want
    {
        LocationName = 'Blackwater Cattle Auction',
        Coords = {x=-853.13, y=-1337.95, z=43.48},
    },
    --[[ {
        LocationName = 'Rhodes Cattle Auction',
        Coords = {x=1332.0, y=-1271.8, z=76.8},
    },
    {
        LocationName = 'Strawberry Cattle Auction',
        Coords = {x=-1837.10, y=-438.56, z=159.53},
    },
    {
        LocationName = 'Armadillo Cattle Auction',
        Coords = {x=-3660.93, y=-2564.88, z=-13.75},
    },
    {
        LocationName = 'St-Denis Cattle Auction',
        Coords = {x=2393.30, y=-1416.46, z=45.76},
    },
    {
        LocationName = 'Annesburg Cattle Auction',
        Coords = {x=2936.83, y=1312.21, z=44.53},
    },
    {
        LocationName = 'Emerald Ranch Cattle Auction',
        Coords = {x = 1420.13, y = 295.07, z = 88.96},
    },
    {
        LocationName = 'Tumbleweed Cattle Auction',
        Coords = {x=-5410.35, y=-2934.25, z=0.92},
    } ]]
}

---------- Admin Configuration (Anyone listed here will be able to create and delete ranches!) -----------
Config.AdminSteamIds = {
    {
        steamid = 'steam:110000102cbb74c', --insert players steam id
    }, 
    --[[ {
        steamid = 'steam:1100001027f26aa'
    },
    {
        steamid = 'steam:11000013f17e30d'
    }, ]]
}
Config.CreateRanchCommand = 'createranch' --name of the command used to create ranches!
Config.ManageRanchsCommand = 'manageranches' --name of the command used to manage ranches!
