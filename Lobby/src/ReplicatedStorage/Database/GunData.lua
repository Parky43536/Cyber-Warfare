local GunData = {
    ["Fireball"] = {
        id = 0,
        name = "Fireball",
        info = "Shots a fireball that deals damage to enemies.",
        image = "8875026796",
        mouseIcon = "Crosshairs",

        damage = 30,
        cooldown = 1,
        range = 1000,
        projectileSpeed = 0.35,

        explosionSize = 30,

        animations = {
            fire = {id = 8797683346, keyframes = {"Fire"}},
        },

        sounds = {
            fire = {id = 46760716, properties = {Volume = 0.2}},
            explosion = {id = 86260556, properties = {Volume = 1.5}},
        },
    },
}

return GunData