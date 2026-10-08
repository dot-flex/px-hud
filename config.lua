masked1337 = { Config = {} }
masked1337.Config.Framework = 'auto'
masked1337.Config.Locale = 'en'

masked1337.Config.SpeedUnit = 'mph'
masked1337.Config.UpdateInterval = 100
masked1337.Config.HideInPause = true
masked1337.Config.HideInCutscene = true
masked1337.Config.ShowOnFoot = false
masked1337.Config.ShowBuildLabel = false
masked1337.Config.BuildLabel = 'masked1337'
masked1337.Config.HideEsxStatus = true
masked1337.Config.Needs = { pollInterval = 2000, statusMax = 1000000 }
masked1337.Config.Stress = {
    enabled = true,
    shootingGain = 2,
    drivingGain = 1,
    speedThreshold = 120,
    calmRelief = 0.5,
    interval = 10000
}

masked1337.Config.Minimap = {

    left = 62, bottom = 102, width = 318, height = 194,
    zoom = 1000,
    frameInsets = { left = 7, top = 4, right = 1, bottom = 12 }
}
masked1337.Config.Postal = {

    resource = 'nearest-postal',
    file = 'new-postals.json'
}

masked1337.Config.Vehicle = {
    enabled = true,
    controls = true,
    engineKey = 'Y', lockKey = 'L', seatbeltKey = 'B',

    lockEvent = nil,

    getFuel = nil
}

masked1337.Config.FishingPrompts = {
    { key = 'LT', keyboard = 'RMB', labelKey = 'fishing_aim' },
    { key = 'RT', keyboard = 'LMB', labelKey = 'fishing_cast' },
    { key = 'B', keyboard = 'R', labelKey = 'fishing_bait' },
    { key = 'Y', keyboard = 'X', labelKey = 'fishing_put_away' }
}
