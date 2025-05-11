function NotifyPlayer(message)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(message)
    DrawNotification(false, false)
end

Config = {
    ServerCallbacks = {},

    CarControllerTime = 1000,
    
    ServerLogo = '../images/mylogo.png',
    FlagProp = 'propfurkan',

    StartTime = 1, -- After pressing the start button, the race will start for the time written here and the vehicles will wait for the time without moving
    PreviewTime = 10, -- After pressing Preview, the blips remain open in the map for the time specified here

    raceItem = "racechip",
    trackItem = "trackchip",
    tabletItem = "racetablet", 

    Notify = {
        ["incar"] = "Get back in the car",
        ["disqualified"] = "You are disqualified from the race",
        ["raceover"] = "The race is over! You've completed all the laps.",
        ["raceovertime"] = "Race is over! Time's up.",
        ["racejoin"] = "You have joined the race.",
    },

    authorization = {  -- Authorization to create a race
        'FMA66194', 
        'TOO29263'
    }

}